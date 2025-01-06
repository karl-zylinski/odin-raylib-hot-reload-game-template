/*
This is more or less a copy of `Default_Temp_Allocator` in base:runtime (that
one is disabled in freestanding build mode, which is the build mode used by for
web). It just forwards everything to the arena in `base:runtime`. That arena is
actually a growing arena made just for the temp allocator.
*/

package main_web

import "base:runtime"

Default_Temp_Allocator :: struct {
	arena: runtime.Arena,
}

default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backing_allocator := context.allocator) {
	_ = runtime.arena_init(&s.arena, uint(size), backing_allocator)
}

default_temp_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: runtime.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location) -> (data: []byte, err: runtime.Allocator_Error) {
	s := (^Default_Temp_Allocator)(allocator_data)
	return runtime.arena_allocator_proc(&s.arena, mode, size, alignment, old_memory, old_size, loc)
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> runtime.Allocator {
	return runtime.Allocator{
		procedure = default_temp_allocator_proc,
		data      = allocator,
	}
}