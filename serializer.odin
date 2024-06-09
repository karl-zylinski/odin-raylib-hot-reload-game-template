/*
Serializer that can both read and write using one proc per data type. It uses
JSON as backing format for the data.

Usage (writing):

s: Serializer
serialize_init_writer(&s)

SomeStruct :: struct {
	field: int,
}

some_struct := SomeStruct {
	field = 7,
}

// this will fail to compile. You must add a serialize_some_struct proc and add
// it to the serialize overload:
serialize(&s, &some_struct)

if data, err := json.marshal(&some_struct); err == nil {
	os.write_entire_file("my_data.json", data)
}

Usage (reading):

some_struct: SomeStruct

if data, ok := os.read_entire_file("my_data.json"); ok {
	if j, err := json.parse(data, parse_integers = true); err == nil {
		s: Serializer
		serialize_init_reader(&s, j)
		serialize(&s, &some_struct)
	}
}

Similar to https://github.com/jakubtomsu/odin-lbp-serialization but uses JSON
as backing instead of a binary blob. It is therefore slower than the 
implementation on the link, and uses more memory. But it produces human-
readable JSON. Good for storing data saved by an editor.
*/

package game

import "core:fmt"
import "base:intrinsics"
import "core:strings"
import "core:encoding/json"

_ :: fmt

Serializer :: struct {
	is_writing: bool,
	cur: ^json.Value,
	root: json.Value,
}

serialize_init_writer :: proc(s: ^Serializer) {
	s.is_writing = true
	s.root = json.Object {}
	s.cur = &s.root
}

serialize_init_reader :: proc(s: ^Serializer, root: json.Value) {
	s.is_writing = false
	s.root = root
	s.cur = &s.root
}

@(require_results)
serialize_int :: proc(s: ^Serializer, val: ^$T) -> bool where intrinsics.type_is_integer(T) && size_of(T) <= size_of(i64) {
	if s.is_writing {
		s.cur^ = json.Integer(val^)
	} else {
		v := s.cur.(json.Integer) or_return
		val^ = T(v)
	}

	return true
}

@(require_results)
serialize_float :: proc(s: ^Serializer, val: ^$T) -> bool where intrinsics.type_is_float(T) {
	if s.is_writing {
		s.cur^ = json.Float(val^)
	} else {
		if v, ok := s.cur.(json.Float); ok {
			val^ = T(v)    
		} else if v, ok := s.cur.(json.Integer); ok {
			val^ = T(v)    
		} else {
			return false
		}
	}

	return true
}

@(require_results)
serialize_bool :: proc(s: ^Serializer, val: ^$T) -> bool where intrinsics.type_is_boolean(T) {
	if s.is_writing {
		s.cur^ = json.Boolean(val^)
	} else {
		v := s.cur.(json.Boolean) or_return
		val^ = T(v)
	}

	return true
}

@(require_results)
serialize_string :: proc(s: ^Serializer, val: ^string) -> bool {
	if s.is_writing {
		s.cur^ = json.String(strings.clone(val^))
	} else {
		v := s.cur.(json.String) or_return
		val^ = strings.clone(string(v))
	}

	return true
}


@(require_results)
serialize_enum :: proc(s: ^Serializer, val: ^$T) -> bool where intrinsics.type_is_enum(T) {
	if s.is_writing {
		s.cur^ = json.Integer(val^)
	} else {
		v := s.cur.(json.Integer) or_return
		val^ = T(v)
	}

	return true
}

@(require_results)
serialize_union_tag_field :: proc(s: ^Serializer, key: string, value: ^$T) -> bool  
where intrinsics.type_is_union(T) {
	tag: i64
	if s.is_writing {
		tag = reflect.get_union_variant_raw_tag(value^)
	}
	serialize_field(s, key, &tag) or_return
	if !s.is_writing {
		reflect.set_union_variant_raw_tag(value^, tag)
	}
	return true
}

@(require_results)
serialize_slice :: proc(s: ^Serializer, data: ^$T/[]$E) -> bool {
	if s.is_writing {
		s.cur^ = make(json.Array, len(data))
	} else {
		arr, is_arr := &s.cur.(json.Array)
		assert(is_arr, "serialize_slice: cur is not json.Array")
		data^ = make([]E, len(arr^))
	}

	for &v, idx in data {
		serialize_array_element(s, idx, &v) or_return
	}
	return true
}

@(require_results)
serialize_fixed_array :: proc(s: ^Serializer, data: ^$T/[$N]$E) -> bool {
	if s.is_writing {
		s.cur^ = make(json.Array, len(data))
	} else {
		_, is_arr := &s.cur.(json.Array)
		assert(is_arr, "serialize_slice: cur is not json.Array")
		data^ = {}
	}

	when intrinsics.type_is_enumerated_array(T) {
		for idx in 0..<len(N) {
			serialize_array_element(s, idx, &data[N(idx)]) or_return
		}
	} else {
		for idx in 0..<N {
			serialize_array_element(s, idx, &data[idx]) or_return
		}	
	}
	return true
}

@(require_results)
serialize_dynamic_array :: proc(s: ^Serializer, data: ^$T/[dynamic]$E, loc := #caller_location) -> bool {
	if s.is_writing {
		s.cur^ = make(json.Array, len(data))
	} else {
		arr, is_arr := &s.cur.(json.Array)
		assert(is_arr, "serialize_dynamic_array: cur is not json.Array")
		data^ = make([dynamic]E, len(arr), loc = loc)
	}

	for &v, idx in data {
		serialize_array_element(s, idx, &v) or_return
	}
	return true
}

@(require_results)
serialize_array_element :: proc(s: ^Serializer, idx: int, v: ^$T) -> bool {
	prev_cur := s.cur
	arr, is_arr := &s.cur.(json.Array)
	assert(is_arr, "serialize_array_element: cur is not json.Array")

	if s.is_writing {
		when intrinsics.type_is_struct(T) || intrinsics.type_is_union(T) {
			arr[idx] = json.Object{}
		} else {
			arr[idx] = json.Value {}    
		}
	}

	s.cur = &arr[idx]
	
	when intrinsics.type_is_union(T) {
		serialize_union_tag_field(s, "__tag", v) or_return
	}

	serialize(s, v) or_return
	s.cur = prev_cur
	return true
}

@(require_results)
serialize_field :: proc(s: ^Serializer, key: string, v: ^$T) -> bool {
	if s.is_writing {
		when intrinsics.type_is_struct(T) {
			if v^ == {} {
				return true
			}
		} else when intrinsics.type_is_numeric(T) {
			if v^ == {} {
				return true
			}
		} else when intrinsics.type_is_boolean(T) {
			if v^ == false {
				return true
			}
		}
	}

	prev_cur := s.cur
	obj, is_obj := &s.cur.(json.Object)
	assert(is_obj, "serialize_field: cur is not json.Object")

	if s.is_writing {
		assert(!(key in obj), "serialize_field writer: cur already has key")

		when intrinsics.type_is_struct(T) || intrinsics.type_is_union(T) { 
			obj[strings.clone(key)] = json.Object {}
		} else {
			obj[strings.clone(key)] = json.Value {}    
		}
	} else {
		if !(key in obj) {
			return true
		}
	}

	s.cur = &obj[key]

	when intrinsics.type_is_union(T) {
		if !s.is_writing && reflect.union_variant_typeid(s.cur^) == json.Integer {
			log.warnf("Enum has become Union: Assuming enum value can be to set raw tag! Value: %v", v)
			ti := type_info_of(T)
			no_nil := false
			if u, ok := ti.variant.(reflect.Type_Info_Union); ok {
				no_nil = u.no_nil
			}

			tag: i64

			serialize_int(s, &tag) or_return

			if !no_nil {
				tag += 1
			}

			reflect.set_union_variant_raw_tag(v^, tag)
		} else {
			serialize_union_tag_field(s, "__tag", v) or_return	
		}
	}

	serialize(s, v) or_return
	s.cur = prev_cur
	return true
}

serialize :: proc {
	// basics
	serialize_int,
	serialize_slice,
	serialize_dynamic_array,
	serialize_fixed_array,
	serialize_bool,
	serialize_float,
	serialize_enum,
	serialize_string,
	serialize_rect,
}

@(require_results)
serialize_rect :: proc(s: ^Serializer, v: ^Rect) -> bool {
	serialize_field(s, "x", &v.x) or_return
	serialize_field(s, "y", &v.y) or_return
	serialize_field(s, "width", &v.width) or_return
	serialize_field(s, "height", &v.height) or_return
	return true
}

@(require_results)
serialize_union_variant_typeid :: proc(s: ^Serializer, key: string, v: ^typeid, $T: typeid) -> bool where intrinsics.type_is_union(T) {
	ti := runtime.type_info_base(type_info_of(T))
	uti, ok := ti.variant.(runtime.Type_Info_Union)

	if !ok {
		return false
	}

	if s.is_writing {
		assert(!uti.no_nil || v^ != nil)
		tag: int

		if v^ != nil {
			for var, i in uti.variants {
				if var.id == v^ {
					tag = i
					if !uti.no_nil {
						tag += 1
					}

					break
				}
			}
		}

		serialize_field(s, key, &tag) or_return
	} else {
		tag: int
		serialize_field(s, key, &tag) or_return

		if tag < len(uti.variants) {
			if uti.no_nil {
				v^ = uti.variants[tag].id    
			} else {
				if tag == 0 {
					v^ = nil
				} else {
					v^ = uti.variants[tag-1].id    
				}
			}
		} else {
			log.error("tag is out of range for union")
			return false
		}
	}

	return true
}
