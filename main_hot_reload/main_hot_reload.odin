// Development game exe. Loads game.dll and reloads it whenever it changes.

package main

import "core:dynlib"
import "core:fmt"
import "core:c/libc"
import "core:os"
import "core:log"
import "core:mem"

when ODIN_OS == .Windows {
	DLL_EXT :: ".dll"
} else when ODIN_OS == .Darwin {
	DLL_EXT :: ".dylib"
} else {
	DLL_EXT :: ".so"
}

copy_dll :: proc(to: string) -> bool {
	exit: i32
	when ODIN_OS == .Windows {
		exit = libc.system(fmt.ctprintf("copy game.dll {0}", to))
	} else {
		exit = libc.system(fmt.ctprintf("cp game" + DLL_EXT + " {0}", to))
	}

	if exit != 0 {
		fmt.printfln("Failed to copy game" + DLL_EXT + " to {0}", to)
		return false
	}

	return true
}

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
	mod_time, mod_time_error := os.last_write_time_by_name("game" + DLL_EXT)
	if mod_time_error != os.ERROR_NONE {
		fmt.printfln(
			"Failed getting last write time of game" + DLL_EXT + ", error code: {1}",
			mod_time_error,
		)
		return
	}

	// NOTE: this needs to be a relative path for Linux to work.
	game_dll_name := fmt.tprintf("{0}game_{1}" + DLL_EXT, "./" when ODIN_OS != .Windows else "", api_version)
	copy_dll(game_dll_name) or_return

	_, ok = dynlib.initialize_symbols(&api, game_dll_name, "game_", "lib")
	if !ok {
		fmt.printfln("Failed initializing symbols: {0}", dynlib.last_error())
	}

	api.api_version = api_version
	api.modification_time = mod_time
	ok = true

	return
}

unload_game_api :: proc(api: ^GameAPI) {
	if api.lib != nil {
		if !dynlib.unload_library(api.lib) {
			fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
		}
	}

	if os.remove(fmt.tprintf("game_{0}" + DLL_EXT, api.api_version)) != 0 {
		fmt.printfln("Failed to remove game_{0}" + DLL_EXT + " copy", api.api_version)
	}
}

main :: proc() {
	context.logger = log.create_console_logger()

	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		err := false

		for _, value in a.allocation_map {
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
		game_dll_mod, game_dll_mod_err := os.last_write_time_by_name("game" + DLL_EXT)

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

		if len(tracking_allocator.bad_free_array) > 0 {
			for b in tracking_allocator.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}

			libc.getchar()
			panic("Bad free detected")
		}

		free_all(context.temp_allocator)
	}

	free_all(context.temp_allocator)
	game_api.shutdown()
	if reset_tracking_allocator(&tracking_allocator) {
		libc.getchar()
	}

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
