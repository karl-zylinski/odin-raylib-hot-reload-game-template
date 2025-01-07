#+build !freestanding
#+build !wasm32, !wasm64p32
#+private

package web_compatible_os

import "core:os"

_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return os.read_entire_file(name, allocator, loc)
}

_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return os.write_entire_file(name, data, truncate)
}