// Handle-based array. A handle-based array is an array that uses handle for 
// references to items. Each handle has an index and a generation. The index is
// just the index of the slot in the array and the generation needs to be the
// same in the handle and on the slot for your handle to still be valid.
// If a slot is reused for another object then the generation will differ,
// this way you don't end up accidentally refering to one object when you
// wanted to refer to some other.
//
// Usage:
// Entity_Handle :: distinct Handle
// Entity :: struct { blabla }
// ha: Handle_Array(Entity, Entity_Handle)
// h := ha_add(&ha, Entity{ bla bla })
// e_ptr := ha_get_ptr(&ha, h) // gets a pointer you can modify
// if e_obj, ok := ha_get(ha, h); ok {
//     // use e_obj	
// }
// ha_remove(&ha, h)
//
// Note num_items in Handle_Array. Set it to the size you
// want. The array is allocated once and then it is set to use
// the panic allocator.

package game

import "core:mem"
import "core:fmt"

_ :: fmt

Handle :: struct {
	idx: u32,
	gen: u32,
}

HANDLE_NONE :: Handle {}

Handle_Array :: struct($T: typeid, $HT: typeid) {
	items: [dynamic]T,
	unused_items: [dynamic]u32,
	allocator: mem.Allocator,
	// if unset, then defaults to 1024
	num_items: int,
}

ha_delete :: proc(ha: Handle_Array($T, $HT), loc := #caller_location) {
	items := ha.items
	items.allocator = ha.allocator
	delete(items, loc)
	delete(ha.unused_items, loc)
}

ha_add :: proc(ha: ^Handle_Array($T, $HT), v: T) -> HT {
	if ha.items == nil {
		ha.allocator = context.allocator

		if ha.num_items == 0 {
			ha.num_items = 1024
		}

		ha.items = make([dynamic]T, 0, ha.num_items)

		// Note that we-preallocate to ha.num_items size and then set
		// allocator to panic allocator. Growing the array is a bit
		// dangerous since you might fetch a pointer using `ha_get_ptr`
		// and then add to the array on the next line and then use
		// thep pointer. If it then grew during that add you might be
		// in trouble.
		ha.items.allocator = mem.panic_allocator()
		ha.unused_items = make([dynamic]u32)
	}

	v := v

	if len(ha.unused_items) > 0 {
		reuse_idx := pop(&ha.unused_items)
		reused := &ha.items[reuse_idx]
		h := reused.handle
		reused^ = v
		reused.handle.idx = u32(reuse_idx)
		reused.handle.gen = h.gen + 1
		return reused.handle
	}

	if len(ha.items) == 0 {
		// Dummy item at idx zero
		append(&ha.items, T{})
	}

	assert(len(ha.items) < ha.num_items - 1, "Ran out of handles!")
	v.handle.idx = u32(len(ha.items))
	v.handle.gen = 1
	append(&ha.items, v)
	return v.handle
}

ha_get :: proc(ha: Handle_Array($T, $HT), h: HT) -> (T, bool) #optional_ok {
	if h.idx == 0 {
		return {}, false
	}

	if int(h.idx) < len(ha.items) && ha.items[h.idx].handle == h {
		return ha.items[h.idx], true
	}

	return {}, false
}

ha_get_ptr :: proc(ha: Handle_Array($T, $HT), h: HT) -> ^T {
	if h.idx == 0 {
		return nil
	}

	if int(h.idx) < len(ha.items) && ha.items[h.idx].handle == h {
		return &ha.items[h.idx]
	}

	return nil
}

ha_remove :: proc(ha: ^Handle_Array($T, $HT), h: HT) {
	if h.idx == 0 {
		return
	}

	if int(h.idx) < len(ha.items) && ha.items[h.idx].handle == h {
		append(&ha.unused_items, h.idx)
		ha.items[h.idx].handle.idx = 0
		ha.items[h.idx].handle.gen += 1
	}
}

ha_valid :: proc(ha: Handle_Array($T, $HT), h: HT) -> bool {
	return ha_get_ptr(ha, h) != nil
}

Handle_Array_Iter :: struct($T: typeid, $HT: typeid) {
	ha: ^Handle_Array(T, HT),
	index: int,
}

ha_make_iter :: proc(ha: ^Handle_Array($T, $HT)) -> Handle_Array_Iter(T, HT) {
	return Handle_Array_Iter(T, HT) { ha = ha }
}

ha_iter :: proc(it: ^Handle_Array_Iter($T, $HT)) -> (val: T, h: HT, cond: bool) {
	cond = it.index < len(it.ha.items)

	for ; cond; cond = it.index < len(it.ha.items) {
		if it.ha.items[it.index].handle.idx == 0 {
			it.index += 1
			continue
		}

		val = it.ha.items[it.index]
		h = val.handle
		it.index += 1
		break
	}

	return
}

ha_iter_ptr :: proc(it: ^Handle_Array_Iter($T, $HT)) -> (val: ^T, h: HT, cond: bool) {
	cond = it.index < len(it.ha.items)

	for ; cond; cond = it.index < len(it.ha.items) {
		if it.ha.items[it.index].handle.idx == 0 {
			it.index += 1
			continue
		}

		val = &it.ha.items[it.index]
		h = val.handle
		it.index += 1
		break
	}

	return
}