package game

import "core:math"
import rl "vendor:raylib"

Collider :: struct {
	is_active: bool,
	rectangle: rl.Rectangle,
}

// WARNING: Colliders are always bottom center aligned
collision_box_update :: proc(e: ^Entity) {
	e.collider.rectangle.x = e.pos.x - (e.collider.rectangle.width / 2)
	e.collider.rectangle.y = e.pos.y - e.collider.rectangle.height
}

process_colliders :: proc(entity_a: ^Entity, cb: proc(e_a: ^Entity, entity_b: ^Entity)) {
	if entity_a.collider.is_active {
		for entity_handle in entity_get_all() {
			ent := entity_get(entity_handle)
			if ent.collider.is_active != true do continue
			if ent.handle.id == entity_a.handle.id do continue
			if rl.CheckCollisionRecs(entity_a.collider.rectangle, ent.collider.rectangle) {
				cb(entity_a, ent)
			}
		}
	}
}

collide_move_and_slide :: proc(entity_a, entity_b: ^Entity) {
	entity_a_rect := entity_a.collider.rectangle
	entity_b_rect := entity_b.collider.rectangle

	overlap := get_rect_overlap(entity_a_rect, entity_b_rect)

	if overlap.x < overlap.y {
		// Push along X axis
		if entity_a_rect.x < entity_b_rect.x {
			entity_a.pos.x -= overlap.x
		} else {
			entity_a.pos.x += overlap.x
		}
	} else {
		// Push along Y axis
		if entity_a_rect.y < entity_b_rect.y {
			entity_a.pos.y -= overlap.y
		} else {
			entity_a.pos.y += overlap.y
		}
	}
}

get_rect_overlap :: proc(a, b: rl.Rectangle) -> rl.Vector2 {
    overlap_x := f32(math.min(a.x + a.width,  b.x + b.width)  - math.max(a.x, b.x))
    overlap_y := f32(math.min(a.y + a.height, b.y + b.height) - math.max(a.y, b.y))
    return rl.Vector2{overlap_x, overlap_y}
}

