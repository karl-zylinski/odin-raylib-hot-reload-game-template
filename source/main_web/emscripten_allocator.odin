/*
This allocator uses the malloc, calloc, free and realloc procs that emscripten
exposes in order to allocate memory. Just like Odin's default heap allocator
this uses proper alignment, so that maps and simd works.
*/

package main_web

import "core:mem"
import "core:c"
import "base:intrinsics"

// This will create bindings to emscripten's implementation of libc
// memory allocation features.
@(default_calling_convention = "c")
foreign {
	calloc  :: proc(num, size: c.size_t) -> rawptr ---
	free    :: proc(ptr: rawptr) ---
	malloc  :: proc(size: c.size_t) -> rawptr ---
	realloc :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---
}

emscripten_allocator :: proc "contextless" () -> mem.Allocator {
	return mem.Allocator{emscripten_allocator_proc, nil}
}

emscripten_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location
) -> (data: []byte, err: mem.Allocator_Error)  {
	// These aligned alloc procs are almost indentical those in
	// `_heap_allocator_proc` in `core:os`. Without the proper alignment you
	// cannot use maps and simd features.

	aligned_alloc :: proc(size, alignment: int, zero_memory: bool, old_ptr: rawptr = nil) -> ([]byte, mem.Allocator_Error) {
		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_mem: rawptr
		if old_ptr != nil {
			original_old_ptr := mem.ptr_offset((^rawptr)(old_ptr), -1)^
			allocated_mem = realloc(original_old_ptr, c.size_t(space+size_of(rawptr)))
		} else if zero_memory {
			// calloc automatically zeros memory, but it takes a number + size
			// instead of just size.
			allocated_mem = calloc(c.size_t(space+size_of(rawptr)), 1)
		} else {
			allocated_mem = malloc(c.size_t(space+size_of(rawptr)))
		}
		aligned_mem := rawptr(mem.ptr_offset((^u8)(allocated_mem), size_of(rawptr)))

		ptr := uintptr(aligned_mem)
		aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a)
		diff := int(aligned_ptr - ptr)
		if (size + diff) > space || allocated_mem == nil {
			return nil, .Out_Of_Memory
		}

		aligned_mem = rawptr(aligned_ptr)
		mem.ptr_offset((^rawptr)(aligned_mem), -1)^ = allocated_mem

		return mem.byte_slice(aligned_mem, size), nil
	}

	aligned_free :: proc(p: rawptr) {
		if p != nil {
			free(mem.ptr_offset((^rawptr)(p), -1)^)
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int) -> ([]byte, mem.Allocator_Error) {
		if p == nil {
			return nil, nil
		}
		return aligned_alloc(new_size, new_alignment, true, p)
	}

	switch mode {
	case .Alloc:
		return aligned_alloc(size, alignment, true)

	case .Alloc_Non_Zeroed:
		return aligned_alloc(size, alignment, false)

	case .Free:
		aligned_free(old_memory)
		return nil, nil

	case .Resize:
		if old_memory == nil {
			return aligned_alloc(size, alignment, true)
		}

		bytes := aligned_resize(old_memory, old_size, size, alignment) or_return

		// realloc doesn't zero the new bytes, so we do it manually.
		if size > old_size {
			new_region := raw_data(bytes[old_size:])
			intrinsics.mem_zero(new_region, size - old_size)
		}

		return bytes, nil

	case .Resize_Non_Zeroed:
		if old_memory == nil {
			return aligned_alloc(size, alignment, false)
		}

		return aligned_resize(old_memory, old_size, size, alignment)

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Resize, .Query_Features}
		}
		return nil, nil

	case .Free_All, .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, .Mode_Not_Implemented
}
