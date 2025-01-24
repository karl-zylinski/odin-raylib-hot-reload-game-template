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

@export
main_start :: proc "c" () {
	context = runtime.default_context()

	// The WASM allocator doesn't seem to work properly in combination with
	// emscripten. There is some kind of conflict with how the manage memory.
	// So this sets up an allocator that uses emscripten's malloc.
	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(1*mem.Megabyte)

	// Since we now use js_wasm32 we should be able to remove this and use
	// context.logger = log.create_console_logger(). However, that one produces
	// extra newlines on web. So it's a bug in that core lib.
	context.logger = create_emscripten_logger()

	web_context = context

	game.game_init_window()
	game.game_init()
}

@export
main_update :: proc "c" () -> bool {
	context = web_context
	game.game_update()
	return game.game_should_run()
}

@export
main_end :: proc "c" () {
	context = web_context
	game.game_shutdown()
	game.game_shutdown_window()
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	context = web_context
	game.game_parent_window_size_changed(int(w), int(h))
}