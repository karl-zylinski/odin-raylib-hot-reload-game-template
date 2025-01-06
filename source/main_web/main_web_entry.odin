/*
These procs are the ones that will be called from `main_wasm.c`.
*/

package main_web

import "base:runtime"
import "core:c"
import "core:mem"
import game ".."

@(private="file")
web_context: runtime.Context

// I'm not sure @thread_local works with WASM. We'll see if anyone makes a
// multi-threaded WASM game!
@(private="file")
@thread_local temp_allocator: Default_Temp_Allocator

@export
web_init :: proc "c" () {
	context = runtime.default_context()
	context.allocator = aligned_raylib_allocator()

	default_temp_allocator_init(&temp_allocator, 1*mem.Megabyte)
	context.temp_allocator = default_temp_allocator(&temp_allocator)
	context.logger = create_web_logger()
	web_context = context

	game.game_init_window()
	game.game_init()
}

@export
web_update :: proc "c" () {
	context = web_context
	game.game_update()
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	context = web_context
	game.game_parent_window_size_changed(int(w), int(h))
}