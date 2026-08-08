/*
Redirects raylib's `TraceLog` output into the logger in `context.logger`.

Without this, raylib prints straight to stdout using C's `printf`. That output
does not go through the Odin logger, and in release builds it does not end up in
`log.txt` (`main_release.odin` only redirects Odin's `os.stdout`, which C's
`printf` doesn't use).

raylib hands the callback a C format string plus a `va_list`. The procs in
`core:fmt` can't expand that: the values live inside the `va_list`, which only a
C-style `vsnprintf` can read. So `vsnprintf` is declared below and used directly.
*/

package game

import "base:runtime"
import "core:c"
import "core:log"
import rl "vendor:raylib"

/*
`vsnprintf` comes from the C runtime that is already being linked, so this adds
no new dependency.

Note that `core:c/libc` can't be used for this. On Windows it foreign-imports
the *static* UCRT (`libucrt.lib`), which collides with the dynamic CRT that
raylib links against (`LNK2005: exit already defined`).
`legacy_stdio_definitions.lib` is the small shim that provides a plain
`vsnprintf` symbol against the dynamic CRT, so importing only that one works.
On web, emscripten provides libc, so no import library is needed at all.
*/
when ODIN_OS == .Windows {
	foreign import libc "system:legacy_stdio_definitions.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System"
} else when ODIN_OS != .JS {
	foreign import libc "system:c"
}

when ODIN_OS == .JS {
	@(private="file", default_calling_convention="c")
	foreign {
		vsnprintf :: proc(buf: [^]byte, count: c.size_t, format: cstring, args: ^c.va_list) -> c.int ---
	}
} else {
	@(private="file", default_calling_convention="c")
	foreign libc {
		vsnprintf :: proc(buf: [^]byte, count: c.size_t, format: cstring, args: ^c.va_list) -> c.int ---
	}
}

// Log messages longer than this are truncated.
//
// A fixed-size buffer is used so that the log callback never allocates. raylib
// can log at times when there is no good allocator to use: for example from
// inside `rl.CloseWindow`, which runs after the final `free_all(context.temp_allocator)`.
RAYLIB_LOG_BUFFER_SIZE :: 1024

// The context used inside `raylib_log_callback`. It needs one because it is a
// `proc "c"`, and those do not have an implicit context.
@(private="file")
g_log_ctx: runtime.Context

/*
Makes raylib log through the logger in `context.logger`.

This must run again after each hot reload: raylib lives in a library that
outlives the game DLL, so it would otherwise keep calling into an unloaded DLL.
*/
set_raylib_log_callback :: proc() {
	g_log_ctx = context

	// Let raylib send everything and have the Odin logger do the filtering
	// using its `lowest_level`. That keeps the log verbosity in a single place.
	rl.SetTraceLogLevel(.ALL)
	rl.SetTraceLogCallback(raylib_log_callback)
}

@(private="file")
raylib_log_callback :: proc "c" (rl_level: rl.TraceLogLevel, message: cstring, args: ^c.va_list) {
	context = g_log_ctx

	// Happens if raylib logs after a hot reload but before
	// `set_raylib_log_callback` has run in the newly loaded DLL.
	if context.logger.procedure == nil {
		return
	}

	level: log.Level

	switch rl_level {
	case .TRACE, .DEBUG: level = .Debug
	case .INFO:          level = .Info
	case .WARNING:       level = .Warning
	case .ERROR:         level = .Error
	case .FATAL:         level = .Fatal
	case .ALL, .NONE:    fallthrough
	case:                level = .Info
	}

	if level < context.logger.lowest_level {
		return
	}

	buf: [RAYLIB_LOG_BUFFER_SIZE]byte
	n := vsnprintf(raw_data(buf[:]), len(buf), message, args)

	if n <= 0 {
		return
	}

	// `vsnprintf` returns the length the message would have had, so this clamps
	// it in case the message was truncated.
	text := string(buf[:min(int(n), len(buf) - 1)])

	// Drop the location header. It would point at this proc, which tells you
	// nothing about where the message came from.
	opts := context.logger.options - log.Location_Header_Opts
	context.logger.procedure(context.logger.data, level, text, opts)
}
