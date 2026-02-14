#+build !wasm32
#+build !wasm64p32

package game

import "core:os"

_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	err: os.Error
	data, err = os.read_entire_file(name, allocator, loc)
	return data, err == nil
}

_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (err: bool) {
	return os.write_entire_file(name, data, truncate = truncate) == nil
}