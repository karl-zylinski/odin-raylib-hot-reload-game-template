// Wraps os.read_entire_file and os.write_entire_file, but they also work with emscripten.

package game

@(require_results)
read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return _read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return _write_entire_file(name, data, truncate)
}