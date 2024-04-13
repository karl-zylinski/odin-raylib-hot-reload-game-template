// Development game exe. Loads game.dll and reloads it whenever it changes.

package main

import "core:dynlib"
import "core:fmt"
import "core:c/libc"
import "core:os"
import "core:time"
import "core:strings"
import "core:log"
import "core:mem"

GameAPI :: struct {
	lib: dynlib.Library,
	init_window: proc(),
	init: proc(),
	update: proc() -> bool,
	shutdown: proc(),
	shutdown_window: proc(),
	memory: proc() -> rawptr,
	memory_size: proc() -> int,
	hot_reloaded: proc(mem: rawptr),
	force_reload: proc() -> bool,
	force_restart: proc() -> bool,
	modification_time: os.File_Time,
	api_version: int,
}

load_game_api :: proc(api_version: int) -> (api: GameAPI, ok: bool) {
	mod_time, mod_time_error := os.last_write_time_by_name("game.dll")

	if mod_time_error != os.ERROR_NONE {
		return
	}

	game_dll_name := fmt.tprintf("game_{0}.dll", api_version)

	if libc.system(fmt.ctprintf("copy game.dll {0}", game_dll_name)) != 0 {
		fmt.println("Failed to copy game.dll to {0}", game_dll_name)
		return
	}

	_, ok = dynlib.initialize_symbols(&api, game_dll_name, "game_", "lib")
	api.api_version = api_version
	api.modification_time = mod_time
	ok = true

	return
}

unload_game_api :: proc(api: ^GameAPI) {
	if api.lib != nil {
		dynlib.unload_library(api.lib)
	}

	if libc.system(fmt.ctprintf("del game_{0}.dll", api.api_version)) != 0 {
		fmt.println("Failed to remove game_{0}.dll copy", api.api_version)
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	
	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator =  mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		err := false

		for key, value in a.allocation_map {
			fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
			err = true
		}

		mem.tracking_allocator_clear(a)
		return err
	}

	game_api_version := 0
	game_api, game_api_ok := load_game_api(game_api_version)

	if !game_api_ok {
		fmt.println("Failed to load Game API")
		return
	}

	game_api_version += 1
	game_api.init_window()
	game_api.init()

	old_game_apis := make([dynamic]GameAPI, default_allocator)

	window_open := true
	for window_open {
		window_open = game_api.update()
		force_reload := game_api.force_reload()
		force_restart := game_api.force_restart()
		reload := force_reload || force_restart
		game_dll_mod, game_dll_mod_err := os.last_write_time_by_name("game.dll")

		if game_dll_mod_err == os.ERROR_NONE && game_api.modification_time != game_dll_mod {
			reload = true
		}

		if reload {
			new_game_api, new_game_api_ok := load_game_api(game_api_version)
			
			if new_game_api_ok {
				if game_api.memory_size() != new_game_api.memory_size() || force_restart {
					game_api.shutdown()
					reset_tracking_allocator(&tracking_allocator)

					for &g in old_game_apis {
						unload_game_api(&g)
					}

					clear(&old_game_apis)
					unload_game_api(&game_api)
					game_api = new_game_api
					game_api.init()
				} else {
					append(&old_game_apis, game_api)
					game_memory := game_api.memory()
					game_api = new_game_api
					game_api.hot_reloaded(game_memory)
				}

				game_api_version += 1
			}
		}

		for b in tracking_allocator.bad_free_array {
			log.error("Bad free at: %v", b.location)
		}

		clear(&tracking_allocator.bad_free_array)
		free_all(context.temp_allocator)
	}

	free_all(context.temp_allocator)
	game_api.shutdown()
	reset_tracking_allocator(&tracking_allocator)

	for &g in old_game_apis {
		unload_game_api(&g)
	}

	delete(old_game_apis)

	game_api.shutdown_window()
	unload_game_api(&game_api)
	mem.tracking_allocator_destroy(&tracking_allocator)
}

// make game use good GPU on laptops etc

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1
