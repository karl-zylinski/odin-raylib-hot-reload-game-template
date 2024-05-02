// This handle-based array gives you a statically allocated array where you can
// use index based handles instead of pointers. The handles have a generation
// that makes sure you don't get bugs when slots are re-used.
// Read more about it here: https://floooh.github.io/2018/06/17/handles-vs-pointers.html  */

package game

Handle :: struct($T: typeid) {
	// idx 0 means unused. Note that slot 0 is a dummy slot, it can never be used.
	idx: u32,
	gen: u32,
}

HandleArrayItem :: struct($T: typeid) {
	item: T,
	handle: Handle(T),
}

// TODO: Add a freelist that uses some kind of bit array... We should be able to
// check 64 item slots at a time that way, but without any dynamic array.
HandleArray :: struct($T: typeid, $N: int) {
	items: #soa[N]HandleArrayItem(T),
	num_items: u32,
}

ha_add :: proc(a: ^HandleArray($T, $N), v: T) -> (Handle(T), bool) #optional_ok {
	for idx in 1..<a.num_items {
		i := &a.items[idx]

		if idx != 0 && i.handle.idx == 0 {
			i.handle.idx = u32(idx)
			i.item = v
			return i.handle, true
		}
	}

	// Index 0 is dummy
	if a.num_items == 0 {
		a.num_items += 1
	}

	if a.num_items == len(a.items) {
		return {}, false
	}

	idx := a.num_items
	i := &a.items[a.num_items]
	a.num_items += 1
	i.handle.idx = idx
	i.handle.gen = 1
	i.item = v
	return i.handle, true
}

ha_get :: proc(a: HandleArray($T, $N), h: Handle(T)) -> (T, bool) {
	if h.idx == 0 {
		return {}, false
	}

	if int(h.idx) < len(a.items) && h.idx < a.num_items && a.items[h.idx].handle == h {
		return a.items[h.idx].item, true
	}

	return {}, false
}

ha_get_ptr :: proc(a: ^HandleArray($T, $N), h: Handle(T)) -> ^T {
	if h.idx == 0 {
		return nil
	}

	if int(h.idx) < len(a.items) && h.idx < a.num_items && a.items[h.idx].handle == h {
		return &a.items[h.idx].item
	}

	return nil
}

ha_remove :: proc(a: ^HandleArray($T, $N), h: Handle(T)) {
	if h.idx == 0 {
		return
	}

	if int(h.idx) < len(a.items) && h.idx < a.num_items && a.items[h.idx].handle == h {
		a.items[h.idx].handle.idx = 0
		a.items[h.idx].handle.gen += 1
	}
}

ha_valid :: proc(a: HandleArray($T, $N), h: Handle(T)) -> bool {
	if h.idx == 0 {
		return false
	}

	return int(h.idx) < len(a.items) && h.idx < a.num_items && a.items[h.idx].handle == h
}

HandleArrayIter :: struct($T: typeid, $N: int) {
	a: ^HandleArray(T, N),
	index: int,
}

ha_make_iter :: proc(a: ^HandleArray($T, $N)) -> HandleArrayIter(T, N) {
	return HandleArrayIter(T, N) { a = a }
}

ha_iter :: proc(it: ^HandleArrayIter($T, $N)) -> (val: T, h: Handle(T), cond: bool) {
	cond = it.index < int(it.a.num_items)

	for ; cond; cond = it.index < int(it.a.num_items) {
		if it.a.items[it.index].handle.idx == 0 {
			it.index += 1
			continue
		}

		val = it.a.items[it.index].item
		h = it.a.items[it.index].handle
		it.index += 1
		break
	}

	return
}

ha_iter_ptr :: proc(it: ^HandleArrayIter($T, $N)) -> (val: ^T, h: Handle(T), cond: bool) {
	cond = it.index < int(it.a.num_items)

	for ; cond; cond = it.index < int(it.a.num_items) {
		if it.a.items[it.index].handle.idx == 0 {
			it.index += 1
			continue
		}

		val = &it.a.items[it.index].item
		h = it.a.items[it.index].handle
		it.index += 1
		break
	}

	return
}
