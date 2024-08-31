// NOTE: You're on the atlas-animation-example branch! This is an extended example that shows
// how to use the atlas builder and atlased animations. There are lots of comments in this file
// that tries to explain how it all works. Also, see the docs in the `atlas_builder` folder to
// see how the atlas builder works.

// This file is compiled as part of the `odin.dll` file. It contains the
// procs that `game.exe` will call, such as:
//
// game_init: Sets up the game state
// game_update: Run once per frame
// game_shutdown: Shuts down game and frees memory
// game_memory: Run just before a hot reload, so game.exe has a pointer to the
//		game's memory.
// game_hot_reloaded: Run after a hot reload so that the `g_mem` global variable
//		can be set to whatever pointer it was in the old DLL.
//
// Note: When compiled as part of the release executable this whole package is imported as a normal
// odin package instead of a DLL.

package game

import "core:math/linalg"
import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

// This loads the atlas at compile time and stores it in the executable, this data is used in `game_hot_reloaded`.
// This means that you don't need atlas.png next to your game after compilation. It will live in
// `game.dll` or `game_release.exe` for release builds.
ATLAS_DATA :: #load("../atlas.png")
PIXEL_WINDOW_HEIGHT :: 180

Player :: struct {
	pos: Vec2,

	// atlas-based animation... See `animation.odin`.
	anim: Animation,
	flip_x: bool,
}

Game_Memory :: struct {	
	player: Player,
	some_number: int,

	// Loaded in `game_hot_reloaded` so you get fresh atlas after each rebuild
	atlas: rl.Texture,

	// Also loaded in `game_hot_reloaded`
	font: rl.Font,
}

// These are here for convinience. `g_mem` is file private so we don't get spaghetti code that uses
// a big global everywhere. But it's still nice to have the atlas and font globally accessible. They
// are set when `game_hot_reloaded` runs.
font: rl.Font
atlas: rl.Texture

@(private="file")
g_mem: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g_mem.player.pos,
		offset = { w/2, h/2 },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {
	input: Vec2

	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	if input.x != 0 {
		animation_update(&g_mem.player.anim, rl.GetFrameTime())
		g_mem.player.flip_x = input.x < 0
	}

	input = linalg.normalize0(input)
	g_mem.player.pos += input * rl.GetFrameTime() * 100
	g_mem.some_number += 1
}

COLOR_BG :: rl.Color { 41, 61, 49, 255 }
COLOR_FG :: rl.Color { 241, 167, 189, 255 }

draw_player :: proc(p: Player) {
	anim_texture := animation_atlas_texture(p.anim)

	// The texture can have a non-zero offset. The offset records how far from the left and the top
	// of the original document this texture starts. This is so the frames can be tightly packed in
	// the atlas, skipping any empty pixels above or to the left of the frame.
	offset_pos := p.pos + anim_texture.offset

	atlas_rect := anim_texture.rect

	dest := Rect {
		offset_pos.x,
		offset_pos.y,
		atlas_rect.width,
		atlas_rect.height,
	}

	if p.flip_x {
		atlas_rect.width = -atlas_rect.width
	}

	// Use document_size for origin as anim_texture.rect.width (and height) may vary from frame to frame.
	origin := Vec2 {
		anim_texture.document_size.x/2,
		anim_texture.document_size.y - 1, // -1 because there's an outline in the player anim that takes an extra pixel
	}

	rl.DrawTexturePro(atlas, atlas_rect, dest, origin, 0, rl.WHITE)
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(COLOR_BG)
	
	// Everything that uses the same camera, shader and texture will end up in the same draw call.
	// This means that the stuff between BeginMode2D and EndMode2D that draws textures, shapes or
	// text can be a single draw call, given that they all use the atlas and they all use the same
	// shader. `g_mem.font` uses the atlas and so does rl.DrawRectangleV because I've pointed the
	// raylib shapes drawing texture to use the atlas (see game_hot_reloaded).
	rl.BeginMode2D(game_camera())
	rl.DrawTextEx(g_mem.font, "This text is in same draw call as player", {-30, 20}, 12, 0, rl.WHITE)

	// Draw a single texture from the atlas. Just draw using atlas texture and fetch the rect of
	// a texture. The name "bush" is there because there's a file in `textures` folder called `bush.ase`
	rl.DrawTextureRec(atlas, atlas_textures[.Bush].rect, {30, -18}, rl.WHITE)
	draw_player(g_mem.player)
	rl.DrawRectangleV({-200, 0}, {400, 16}, COLOR_FG)
	rl.EndMode2D()

	// Here we switch to the UI camera. The stuff drawn in here will be in a separate draw call.
	rl.BeginMode2D(ui_camera())
	rl.DrawTextEx(g_mem.font, fmt.ctprintf("some_number: %v\nplayer_pos: %v", g_mem.some_number, g_mem.player.pos), {5, 5}, 20, 0, rl.WHITE)
	rl.EndMode2D()

	// Total draw calls: 2

	rl.EndDrawing()
}

@(export)
game_update :: proc() -> bool {
	update()
	draw()
	return !rl.WindowShouldClose()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template! With atlased animations!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		some_number = 100,
		player = {
			// It's called Player because there is a `player.ase` file in `textures` folder that has
			// more than one frame. Also, if an ase file has tags in it, then those tags will be
			// used to create several animations. You can look in `Animation_Name` enum in atlas.odin.
			anim = animation_create(.Player),
		},
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_shutdown :: proc() { 
	rl.UnloadTexture(atlas)
	delete_atlased_font(g_mem.font)
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

delete_atlased_font :: proc(font: rl.Font) {
	delete(slice.from_ptr(font.glyphs, int(font.glyphCount)))
	delete(slice.from_ptr(font.recs, int(font.glyphCount)))
}

// This uses the letters in the atlas to create a raylib font. Since this font is in the atlas
// it can be drawn in the same draw call as game graphics in the atlas. Don't use rl.UnloadFont() to
// destroy this font, instead use `delete_atlased_font`, since we've set up the memory ourselves.
load_atlased_font :: proc() -> rl.Font {
	num_glyphs := len(atlas_glyphs)
	font_rects := make([]Rect, num_glyphs)
	glyphs := make([]rl.GlyphInfo, num_glyphs)

	for ag, idx in atlas_glyphs {
		font_rects[idx] = ag.rect
		glyphs[idx] = {
			value = ag.value,
			offsetX = i32(ag.offset_x),
			offsetY = i32(ag.offset_y),
			advanceX = i32(ag.advance_x),
		}
	} 

	return {
		baseSize = ATLAS_FONT_SIZE,
		glyphCount = i32(num_glyphs),
		glyphPadding = 0,
		texture = atlas,
		recs = raw_data(font_rects),
		glyphs = raw_data(glyphs),
	}
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)

	// Atlas can change on rebuild, so reload it.
	rl.UnloadTexture(g_mem.atlas)
	atlas_image := rl.LoadImageFromMemory(".png", raw_data(ATLAS_DATA), i32(len(ATLAS_DATA)))
	g_mem.atlas = rl.LoadTextureFromImage(atlas_image)
	atlas = g_mem.atlas
	rl.UnloadImage(atlas_image)

	// Reload font since we reloaded atlas.
	delete_atlased_font(g_mem.font)
	g_mem.font = load_atlased_font()
	font = g_mem.font

	// Set the shapes drawing texture, this makes rl.DrawRectangleRec etc use the atlas
	rl.SetShapesTexture(atlas, shapes_texture_rect)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}