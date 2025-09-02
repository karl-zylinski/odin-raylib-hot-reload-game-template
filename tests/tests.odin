package tests
import gm "../source"

import "core:testing"

init_test_memory :: proc() {
	mem := new(gm.GameMemory)
	mem^ = gm.GameMemory{
		run = true
	}
	gm.game_hot_reloaded(mem)
}

@(test)
entity_create_basic :: proc(t: ^testing.T) {
	init_test_memory()

	ent1 := gm.entity_create(.PLAYER)
	idx1 := ent1.handle.index
	id1 := ent1.handle.id

	testing.expect(t, gm.entity_is_valid(ent1), "ent1 should be valid after creation")
	testing.expect(t, idx1 > 0, "ent1 should have a positive index")
	testing.expect(t, id1 > 0, "ent1 should have a positive id")

	ent2 := gm.entity_create(.PLAYER)
	idx2 := ent2.handle.index
	id2 := ent2.handle.id

	testing.expect(t, gm.entity_is_valid(ent2), "ent2 should be valid after creation")
	testing.expect(t, idx2 == idx1 + 1, "ent2 index should follow ent1 when no free indices exist")
	testing.expect(t, id2 == id1 + 1, "ent2 id should increment")

}

@(test)
entity_destroy_reuses_index_and_invalidates :: proc(t: ^testing.T) {
	init_test_memory()

	ent1 := gm.entity_create(.PLAYER)
	_ = gm.entity_create(.PLAYER) // occupy next slot

	idx1 := ent1.handle.index
	id_before := ent1.handle.id

	gm.entity_destroy(ent1)
	testing.expect(t, !gm.entity_is_valid(ent1), "ent1 should be invalid after destruction")

	ent3 := gm.entity_create(.PLAYER)
	idx3 := ent3.handle.index
	id3 := ent3.handle.id

	testing.expect(t, idx3 == idx1, "ent3 should reuse ent1's freed index")
	testing.expect(t, id3 > id_before, "ent3 should have a strictly increasing id")

}

@(test)
entity_get_valid_and_invalid :: proc(t: ^testing.T) {
	init_test_memory()

	ent := gm.entity_create(.PLAYER)
	h := ent.handle

	e_ok, ok := gm.entity_get(h)
	testing.expect(t, ok, "entity_get should succeed for a valid handle")
	testing.expect(t, gm.entity_is_valid(e_ok), "Retrieved entity should be valid")

	// Invalid: zero handle
	zero_h := gm.Handle{}
	_, ok_zero := gm.entity_get(zero_h)
	testing.expect(t, !ok_zero, "entity_get should fail for zero handle")

	// Invalid: out-of-range index
	bad_index_h := gm.Handle{index = 999999, id = 1}
	_, ok_bad_idx := gm.entity_get(bad_index_h)
	testing.expect(t, !ok_bad_idx, "entity_get should fail for out-of-range index")

	// Invalid: mismatched id
	bad_id_h := gm.Handle{index = h.index, id = h.id + 12345}
	_, ok_bad_id := gm.entity_get(bad_id_h)
	testing.expect(t, !ok_bad_id, "entity_get should fail for mismatched id")

}

@(test)
entity_clear_all_empties_scratch :: proc(t: ^testing.T) {
	init_test_memory()

	_ = gm.entity_create(.PLAYER)
	_ = gm.entity_create(.PLAYER)
	_ = gm.entity_create(.PLAYER)

	gm.rebuild_scratch()
	handles := gm.entity_get_all()
	testing.expect(t, len(handles) == 3, "Should have three entities in scratch list before clear")

	gm.entity_clear_all()
	gm.rebuild_scratch()
	handles_after := gm.entity_get_all()
	testing.expect(t, len(handles_after) == 0, "All entities should be cleared and scratch empty")
}
