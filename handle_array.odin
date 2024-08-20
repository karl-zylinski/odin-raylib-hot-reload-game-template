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
// Note that your item type currently needs to have a 'handle' field. I'll try to make a new version
// of the handle array that does not do this.
//
// Usage: See `ha_test` at the end of this file.
// 
// IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT 
// You should call `ha_commit_new` every now and then (in a game for example at the end of the
// frame) in order to move things from `new_items` into `items` of the handle-based araray. This
// split is done for these reasons:
// - `items` is a dynamic array. If you fetch a pointer using `ha_get_ptr` and then add to the
//   handle-based array, then the pointer you have in flight might get invalided due to `items`
//   growing.
// - So we shouldn't grow `items` except at places where you have no pointers in flight (end of the
//   frame).
// - So we have the `new_items`array where items are allocated using a growing virtual memory arena.
//   This way we can still hand point pointers to things in the `new_items` array, since adding to
//   it won't invalidate the items in there.
// - Call `ha_commit_new` at a good location to move things from `new_items` to `items`. Do this
//   when you are sure that you have no pointers to things in the handle-based array in flight. In a
//   game this can usually be done at the end of the frame.
package game

import "core:fmt"
import "core:mem"
import "core:slice"
import vmem "core:mem/virtual"

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

	// To make sure we do not invalidate `items` in the middle of a frame, while there are pointers
	// to things it, we add new items to this, and the new items are allocated using the growing
	// virtual arena `new_items_arena`. Run `ha_commit_new` once in a while to move things from
	new_items: [dynamic]^T,
	new_items_arena: vmem.Arena,
}

ha_delete :: proc(ha: Handle_Array($T, $HT), loc := #caller_location) {
	delete(ha.items, loc)
	delete(ha.unused_items, loc)
	new_items_arena := ha.new_items_arena
	vmem.arena_destroy(&new_items_arena)
}

ha_clear :: proc(ha: ^Handle_Array($T, $HT), loc := #caller_location) {
	clear(&ha.items)
	clear(&ha.unused_items)
	vmem.arena_free_all(&ha.new_items_arena)
	ha.new_items = {}
}

// Call this at a safe space when there are no pointers in flight. It will move things from
// new_items into items, potentially making it grow. Those new items live on a growing virtual
// memory arena until this is called.
ha_commit_new :: proc(ha: ^Handle_Array($T, $HT), loc := #caller_location) {
	if len(ha.items) == 0 {
		// Dummy item at idx zero
		append(&ha.items, T{})
	}

	for ni in ha.new_items {
		if ni == nil {
			// We must add these, if we don't the indices get out of order with regards to handles
			// we have handed out. We'll just add them as empty objects and then put the index into
			// unused items.
			unused_item_idx := len(ha.items)
			append(&ha.items, T {
				handle = {
					gen = 1,
				},
			})

			append(&ha.unused_items, u32(unused_item_idx))
			continue
		}

		append(&ha.items, ni^)
	}

	vmem.arena_free_all(&ha.new_items_arena)
	ha.new_items = {}
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

	new_items_allocator := vmem.arena_allocator(&ha.new_items_arena)
	new_item := new(T, new_items_allocator)
	new_item^ = v
	new_item.handle.idx = u32(len(ha.items) + len(ha.new_items))
	new_item.handle.gen = 1

	if ha.new_items == nil {
		ha.new_items = make([dynamic]^T, new_items_allocator)
	}

	append(&ha.new_items, new_item)
	return new_item.handle
}

ha_get :: proc(ha: Handle_Array($T, $HT), h: HT) -> (T, bool) #optional_ok {
	if ptr := ha_get_ptr(ha, h); ptr != nil {
		return ptr^, true
	}

	return {}, false
}

ha_get_ptr :: proc(ha: Handle_Array($T, $HT), h: HT) -> ^T {
	if h.idx == 0 || h.idx < 0 {
		return nil
	}

	if int(h.idx) >= len(ha.items) {
		// The item we look for might be in `new_items`, so look in there too
		new_idx := h.idx - u32(len(ha.items))
		
		if new_idx >= u32(len(ha.new_items)) {
			return nil
		}

		if item := ha.new_items[new_idx]; item != nil && item.handle == h {
			return item
		}

		return nil
	}

	if item := &ha.items[h.idx]; item.handle == h {
		return item
	}

	return nil
}

ha_remove :: proc(ha: ^Handle_Array($T, $HT), h: HT) {
	if h.idx == 0 || h.idx < 0 {
		return
	}

	if int(h.idx) >= len(ha.items) {
		new_idx := h.idx - u32(len(ha.items))
		
		if new_idx < u32(len(ha.new_items)) {
			// This stops this item from being added during `ha_commit_new`
			ha.new_items[new_idx] = nil
		}

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
	val_ptr: ^T

	val_ptr, h, cond = ha_iter_ptr(it)

	if val_ptr != nil {
		val = val_ptr^
	}

	return
}

ha_iter_ptr :: proc(it: ^Handle_Array_Iter($T, $HT)) -> (val: ^T, h: HT, cond: bool) {
	cond = it.index < len(it.ha.items) + len(it.ha.new_items)

	for ; cond; cond = it.index < len(it.ha.items) + len(it.ha.new_items) {
		// Handle items in new_items
		if it.index >= len(it.ha.items) {
			idx := it.index - len(it.ha.items)

			if it.ha.new_items[idx] == nil {
				it.index += 1
				continue
			}

			val = it.ha.new_items[idx]
			h = val.handle
			it.index += 1
			break
		}

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
	assert(h4.idx == 4)

	assert(h1.idx == 1)
	assert(h2.idx == 2)
	assert(h3.idx == 3)
	assert(h1.gen == 1)
	assert(h2.gen == 1)
	assert(h3.gen == 1)

	if _, ok := ha_get(ha, h2); ok {
		panic("h2 should not be valid")
	}

	if h4_ptr := ha_get_ptr(ha, h4); h4_ptr != nil {
		assert(h4_ptr.pos == {4, 2})
		h4_ptr.pos = {5, 2}
	} else {
		panic("h4 should be valid")
	}

	if h4_val, ok := ha_get(ha, h4); ok {
		assert(h4_val.pos == {5, 2})
	} else {
		panic("h4 should be valid")
	}

	// This call moves new items from new_items into items. Should be run every now and then when
	// you know you don't have any pointers that you need. In a game this can be at end of frame.
	ha_commit_new(&ha)

	if h4_val, ok := ha_get(ha, h4); ok {
		assert(h4_val.pos == {5, 2})
	} else {
		panic("h4 should be valid")
	}

	ha_remove(&ha, h4)
	h5 := ha_add(&ha, Ha_Test_Entity {pos = {6, 2}})
	assert(h5.idx == 4)

	ha_delete(ha)
}