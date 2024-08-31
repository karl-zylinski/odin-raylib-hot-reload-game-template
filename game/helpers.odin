// generic odin helpers

package game

import "core:reflect"
import "core:strings"
import "base:intrinsics"

increase_or_wrap_enum :: proc(e: $T) -> T {
	ei := int(e) + 1

	if ei >= len(T) {
		ei = 0
	}

	return T(ei)
}

union_type :: proc(a: any) -> typeid {
	return reflect.union_variant_typeid(a)
}

temp_cstring :: proc(s: string) -> cstring {
	return strings.clone_to_cstring(s, context.temp_allocator)
}

// There is a remap in core:math but it doesn't clamp in the new range, which I
// always want.
remap :: proc "contextless" (old_value, old_min, old_max, new_min, new_max: $T) -> (x: T) where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	old_range := old_max - old_min
	new_range := new_max - new_min
	if old_range == 0 {
		return new_range / 2
	}
	return clamp(((old_value - old_min) / old_range) * new_range + new_min, new_min, new_max)
}