/*
For making a release exe that does not use hot reload.
*/

package main_release

import "core:log"
import "core:os"
import "core:path/filepath"
import "core:mem"
import game ".."

_ :: mem

USE_TRACKING_ALLOCATOR :: #config(USE_TRACKING_ALLOCATOR, false)

main :: proc() {
	// Set working dir to dir of executable.
	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path), context.temp_allocator)
	os.set_current_directory(exe_dir)
	
	mode: int = 0
	when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		mode = os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH
	}

	logh, logh_err := os.open("log.txt", (os.O_CREATE | os.O_TRUNC | os.O_RDWR), mode)

	if logh_err == os.ERROR_NONE {
		os.stdout = logh
		os.stderr = logh
	}

	logger_alloc := context.allocator
	logger := logh_err == os.ERROR_NONE ? log.create_file_logger(logh, allocator = logger_alloc) : log.create_console_logger(allocator = logger_alloc)
	context.logger = logger

	when USE_TRACKING_ALLOCATOR {
		default_allocator := context.allocator
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
	}

	game.game_init_window()
	game.game_init()

	for game.game_should_run() {
		game.game_update()
	}

	free_all(context.temp_allocator)
	game.game_shutdown()
	game.game_shutdown_window()

	when USE_TRACKING_ALLOCATOR {
		for _, value in tracking_allocator.allocation_map {
			log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
		}

		mem.tracking_allocator_destroy(&tracking_allocator)
	}

	if logh_err == os.ERROR_NONE {
		log.destroy_file_logger(logger, logger_alloc)
	}
}

// make game use good GPU on laptops etc

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1