/*
These procs are the ones that will be called from `main_wasm.c`.
*/

#+build wasm32, wasm64p32

package main_web

import "base:runtime"
import "core:c"
import "core:mem"
import rl "vendor:raylib"
import "../game"

@(private="file")
wasm_context: runtime.Context

// I'm not sure @thread_local works with WASM. We'll see if anyone makes a
// multi-threaded WASM game!
@(private="file")
@thread_local temp_allocator: WASM_Temp_Allocator

@export
web_init :: proc "c" () {
	context = runtime.default_context()
	context.allocator = rl.MemAllocator()

	wasm_temp_allocator_init(&temp_allocator, 1*mem.Megabyte)
	context.temp_allocator = wasm_temp_allocator(&temp_allocator)
	context.logger = create_wasm_logger()
	wasm_context = context

	game.game_init_window()
	game.game_init()
}

@export
web_update :: proc "c" () {
	context = wasm_context
	game.game_update()
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	rl.SetWindowSize(w, h)
}