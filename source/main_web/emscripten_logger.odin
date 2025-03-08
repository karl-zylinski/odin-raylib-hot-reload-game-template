/*
This logger is largely a copy of the console logger in `core:log`, but it uses
emscripten's `puts` proc to write into he console of the web browser.

This is more or less identical to the logger in Aronicu's repository:
https://github.com/Aronicu/Raylib-WASM/tree/main
*/

package main_web

import "core:c"
import "core:fmt"
import "core:log"
import "core:strings"

Emscripten_Logger_Opts :: log.Options{.Level, .Short_File_Path, .Line}

create_emscripten_logger :: proc (lowest := log.Level.Debug, opt := Emscripten_Logger_Opts) -> log.Logger {
	return log.Logger{data = nil, procedure = logger_proc, lowest_level = lowest, options = opt}
}

// This create's a binding to `puts` which will be linked in as part of the
// emscripten runtime.
@(default_calling_convention = "c")
foreign {
	puts :: proc(buffer: cstring) -> c.int ---
}

@(private="file")
logger_proc :: proc(
	logger_data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location := #caller_location
) {
	b := strings.builder_make(context.temp_allocator)
	strings.write_string(&b, Level_Headers[level])
	do_location_header(options, &b, location)
	fmt.sbprint(&b, text)

	if bc, bc_err := strings.to_cstring(&b); bc_err == nil {
		puts(bc)
	}
}

@(private="file")
Level_Headers := [?]string {
	0 ..< 10 = "[DEBUG] --- ",
	10 ..< 20 = "[INFO ] --- ",
	20 ..< 30 = "[WARN ] --- ",
	30 ..< 40 = "[ERROR] --- ",
	40 ..< 50 = "[FATAL] --- ",
}

@(private="file")
do_location_header :: proc(opts: log.Options, buf: ^strings.Builder, location := #caller_location) {
	if log.Location_Header_Opts & opts == nil {
		return
	}
	fmt.sbprint(buf, "[")
	file := location.file_path
	if .Short_File_Path in opts {
		last := 0
		for r, i in location.file_path {
			if r == '/' {
				last = i + 1
			}
		}
		file = location.file_path[last:]
	}

	if log.Location_File_Opts & opts != nil {
		fmt.sbprint(buf, file)
	}
	if .Line in opts {
		if log.Location_File_Opts & opts != nil {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprint(buf, location.line)
	}

	if .Procedure in opts {
		if (log.Location_File_Opts | {.Line}) & opts != nil {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprintf(buf, "%s()", location.procedure)
	}

	fmt.sbprint(buf, "] ")
}
