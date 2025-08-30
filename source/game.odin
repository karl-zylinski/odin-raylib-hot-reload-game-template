/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:math"
import rl "vendor:raylib"

DEBUG :: true
PIXEL_WINDOW_HEIGHT :: 180

Handle :: struct {
	index: int,
	// Makes trying to debug thing a bit easier if we know for a fact
	// an entity cannot have the same ID as another one.
	id:    int,
}

GameMemory :: struct {
	// Entity
	entity_top_count: int,
	latest_entity_id: int,
	entities:         [MAX_ENTITIES]Entity,
	entity_free_list: [dynamic]int,
	player_handle:    Handle,
	screen_shake:     ScreenShake,
	textures:         Textures,
	sounds:           Sounds,
	soundtrack:       rl.Music,
	run:              bool,
	scratch:          struct {
		all_entities: []Handle,
	},
}

ScreenShake :: struct {
	is_screen_shaking:        bool,
	screen_shake_time:        f64,
	screen_shake_timeElapsed: f64,
	screen_shake_dropOff:     f64,
	screen_shake_speed:       f64,
}

Sounds :: struct {}

// WARNING: if you add a texture you MUST also unload it game_shutdown
Textures :: struct {
	player_run: rl.Texture2D,
}

g: ^GameMemory

rebuild_scratch :: proc() {
	/*
	* Entities
	*/
	all_ents := make([dynamic]Handle, 0, len(g.entities), context.temp_allocator)
	for &e in g.entities {
		if !entity_is_valid(e) do continue
		append(&all_ents, e.handle)
	}
	// Greedy selection sort by z
	for i in 0 ..< len(all_ents) {
		min_index := i
		for j in i + 1 ..< len(all_ents) {
			ea := entity_get(all_ents[j])
			em := entity_get(all_ents[min_index])
			if ea.z_index < em.z_index {
				min_index = j
			}
		}
		if min_index != i {
			all_ents[i], all_ents[min_index] = all_ents[min_index], all_ents[i]
		}
	}
	// Sort entities by their z value (lower z drawn first, higher on top)
	g.scratch.all_entities = all_ents[:]
}

get_player :: proc() -> (player: ^Entity, ok: bool) #optional_ok {
	return entity_get(g.player_handle)
}

set_screen_shake :: proc(time_s, drop_off, speed: f64) {
	g.screen_shake.screen_shake_time = time_s
	g.screen_shake.screen_shake_dropOff = drop_off
	g.screen_shake.screen_shake_speed = speed
	g.screen_shake.is_screen_shaking = true
	g.screen_shake.screen_shake_timeElapsed = g.screen_shake.screen_shake_time
}

get_screen_shake :: proc() -> (target: rl.Vector2) {
	g.screen_shake.screen_shake_timeElapsed -=
		f64(rl.GetFrameTime()) * g.screen_shake.screen_shake_dropOff

	target.x =
		target.x +
		f32(g.screen_shake.screen_shake_timeElapsed) *
			math.sin_f32(f32(rl.GetTime()) * f32(g.screen_shake.screen_shake_speed))
	target.y =
		target.y +
		f32(g.screen_shake.screen_shake_timeElapsed) *
			math.sin_f32(f32(rl.GetTime()) * f32(g.screen_shake.screen_shake_speed) * 1.3 + 1.7)

	if (g.screen_shake.screen_shake_timeElapsed <= 0) {
		g.screen_shake.is_screen_shaking = false
	}

	return
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	target := rl.Vector2(0)
	target += get_screen_shake()

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = target, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

update :: proc() {

	g.scratch = {}
	rebuild_scratch()
	rl.UpdateMusicStream(g.soundtrack)
	// big :update time
	for handle in entity_get_all() {
		e := entity_get(handle)
		// animation for every entity
		animate(e)

		e.on_update(e)

		collision_box_update(e)
	}

	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(game_camera())
	for handle in entity_get_all() {
		e := entity_get(handle)^ // dereference because we don't want to edit it
		e.on_draw(e)
	}
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	// rl.DrawText(
	// 	fmt.ctprintf("some_number: %v\nplayer_pos: %v", g.some_number, g.player_pos),
	// 	5,
	// 	5,
	// 	8,
	// 	rl.WHITE,
	// )

	rl.EndMode2D()

	rl.EndDrawing()
}

@(export)
game_update :: proc() {
	update()
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(GameMemory)

	g^ = GameMemory {
		run = true,
		textures = {player_run = rl.LoadTexture("assets/CorgiRun.png")},
	}

	entity_create(.PLAYER)

	game_hot_reloaded(g)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {

	rl.UnloadTexture(g.textures.player_run)

	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(GameMemory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^GameMemory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
