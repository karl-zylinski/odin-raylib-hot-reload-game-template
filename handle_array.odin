// A handle-based array is an array where you can use handles to refer to items in the array. It's a
// great alternative to using pointers for the same purpose. This article explains why:
// https://floooh.github.io/2018/06/17/handles-vs-pointers.html
//
// The main idea is: If you need to permanentely store a reference to an object in an array, then
// store a handle, not a pointer.
//
// Each handle has an index and a generation. The index is just the index of the slot in the array
// and the generation needs to be the same in the handle and on the slot for your handle to still be
// valid. If a slot is reused for another object then the generation will differ, this way you don't
// end up accidentally refering to one object when you wanted to refer to some other. Stuff like
// that can happen when one part of your game holds a handle to an object while another part
// removes it from the array, and subsequently putting something new at the same slot. With the
// differing generation for that slot it is thus detectable that the item has been replaced.
//
// Usage: See `ha_test` at the end of this file.
//
// Note: There is a `ha_get` that returns an item, but no `ha_get_ptr` that returns a pointer to
// an item, instead it is recommended to use `ha_set` to update the whole item after fetching it
// using `ha_get`. Even though you should never store a pointer permanently, even having a pointer
// temporarily can be problematic if you for example fetch the pointer and right after that add to
// the handle-based array, which can make it grow (reallocating the array). You could work around
// these issues by making `items` of `Handle_Array` a fixed array or allocating a big dynamic array
// up-front and then changing its allocator to the panic allocator. If you do that, then you could
// add a `ha_get_ptr` proc.

package game

import "core:fmt"
import "core:mem"

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
}

ha_delete :: proc(ha: Handle_Array($T, $HT), loc := #caller_location) {
	delete(ha.items, loc)
	delete(ha.unused_items, loc)
}

ha_clear :: proc(ha: ^Handle_Array($T, $HT), loc := #caller_location) {
	clear(&ha.items)
	clear(&ha.unused_items)
}

ha_clone :: proc(ha: Handle_Array($T, $HT), allocator := context.allocator, loc := #caller_location) -> Handle_Array(T, HT) {
	return Handle_Array(T, HT) {
		items = slice.clone_to_dynamic(ha.items[:], allocator, loc),
		unused_items = slice.clone_to_dynamic(ha.unused_items[:], allocator, loc),
		allocator = allocator,
	}
}

ha_add :: proc(ha: ^Handle_Array($T, $HT), v: T, loc := #caller_location) -> HT {
	if ha.items == nil {
		if ha.allocator == {} {
			ha.allocator = context.allocator
		}

		ha.items = make([dynamic]T, ha.allocator, loc)
		ha.unused_items = make([dynamic]u32, ha.allocator, loc)
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

	v.handle.idx = u32(len(ha.items))
	v.handle.gen = 1
	append(&ha.items, v)
	return v.handle
}

ha_get :: proc(ha: Handle_Array($T, $HT), h: HT) -> (T, bool) #optional_ok {
	if h.idx == 0 || h.idx < 0 || int(h.idx) >= len(ha.items) {
		return {}, false
	}

	if item := ha.items[h.idx]; item.handle == h {
		return item, true
	}

	return {}, false
}

ha_set_with_handle :: proc(ha: ^Handle_Array($T, $HT), h: HT, new_item: T) -> bool {
	if h.idx == 0 || h.idx < 0 || int(h.idx) >= len(ha.items) {
		return false
	}

	if item := &ha.items[h.idx]; item.handle == h {
		item^ = new_item
		
		// make sure handle is correct in case someone messed with the handle in `new_item`.
		item.handle = h
	}

	return false
}

ha_set_with_implicit_handle :: proc(ha: ^Handle_Array($T, $HT), item: T) -> bool {
	return ha_set_with_handle(ha, item.handle, item)
}

ha_set :: proc {
	ha_set_with_handle,
	ha_set_with_implicit_handle,
}

ha_remove :: proc(ha: ^Handle_Array($T, $HT), h: HT) {
	if h.idx == 0 || h.idx < 0 || int(h.idx) >= len(ha.items) {
		return
	}

	if item := &ha.items[h.idx]; item.handle == h {
		append(&ha.unused_items, h.idx)

		// This makes the item invalid. We'll set the index back if the slot is reused.
		item.handle.idx = 0
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
	return { ha = ha }
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

// Test handle array and basic usage documentation.

ha_test :: proc() {
	Ha_Test_Entity :: struct {
		handle: Ha_Test_Entity_Handle,
		pos: [2]f32,
		vel: [2]f32,
	}

	Ha_Test_Entity_Handle :: distinct Handle

	ha: Handle_Array(Ha_Test_Entity, Ha_Test_Entity_Handle)

	h1 := ha_add(&ha, Ha_Test_Entity {pos = {1, 2}})
	h2 := ha_add(&ha, Ha_Test_Entity {pos = {2, 2}})
	h3 := ha_add(&ha, Ha_Test_Entity {pos = {3, 2}})

	ha_remove(&ha, h2)

	// This one will reuse the slot h2 had
	h4 := ha_add(&ha, Ha_Test_Entity {pos = {4, 2}})
	assert(h2.idx == h4.idx)

	assert(h1.idx == 1)
	assert(h2.idx == 2)
	assert(h3.idx == 3)
	assert(h4.idx == 2)
	assert(h4.gen == 2)
	assert(h1.gen == 1)
	assert(h2.gen == 1)
	assert(h3.gen == 1)

	if _, ok := ha_get(ha, h2); ok {
		panic("h2 should not be valid")
	}

	if h4_val, ok := ha_get(ha, h4); ok {
		assert(h4_val.pos == {4, 2})
		h4_val.pos = {5, 2}
		ha_set(&ha, h4, h4_val)
	} else {
		panic("h4 should be valid")
	}

	if h4_val, ok := ha_get(ha, h4); ok {
		assert(h4_val.pos == {5, 2})
	} else {
		panic("h4 should be valid")
	}

	ha_delete(ha)
}
