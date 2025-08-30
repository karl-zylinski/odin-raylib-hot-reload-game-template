package game

import "core:fmt"
import rl "vendor:raylib"

MAX_ENTITIES :: 2048

zero_entity: Entity // #readonly for zeroing entities


EntityKind :: enum {
	NIL,
	PLAYER,
}

Entity :: struct {
	handle:         Handle,
	kind:           EntityKind,
	pos:            rl.Vector2,
	on_update:      proc(entity: ^Entity),
	on_draw:        proc(entity: Entity),
	z_index:        int,
	collider:       Collider,
	velocity:       rl.Vector2,
	rotation:       f32,
	scale:          f32,
	has_physics:    bool,
	animation:      Animation,
	hidden:         bool,
	is_initialized: bool,
	created_on:     f64,
}

entity_init :: proc(e: ^Entity, initialize: proc(entity: ^Entity)) {
	if !e.is_initialized {
		initialize(e)
		e.is_initialized = true
	}
}

entity_draw_default :: proc(e: Entity) {
	texture := e.animation.texture
	offset := get_texture_position(e)
	destination := rl.Rectangle {
		x      = offset.x,
		y      = offset.y,
		width  = f32(texture.width) * e.scale / f32(e.animation.frame_count),
		height = f32(texture.height) * e.scale,
	}

	src := get_source_rect(e.animation)
	if e.animation.flip_x {
		src.width = -src.width
		src.x += -src.width
	}

	rl.DrawTexturePro(texture, src, destination, e.rotation, e.scale, rl.WHITE)
	if DEBUG {
		rl.DrawCircleV(e.pos, 2, rl.PINK)
		rl.DrawRectangleRec(e.collider.rectangle, rl.ColorAlpha(rl.BLUE, .50))
	}
}

get_texture_position :: proc(e: Entity) -> rl.Vector2 {
	texture_width := f32(e.animation.texture.width / i32(e.animation.frame_count))
	texture_height := f32(e.animation.texture.height)

	return rl.Vector2{e.pos.x - texture_width / 2 * e.scale, e.pos.y - texture_height / 2}
}

entity_is_valid :: proc {
	entity_is_valid_no_ptr,
	entity_is_valid_ptr,
}
entity_is_valid_no_ptr :: proc(entity: Entity) -> bool {
	return entity.handle.id != 0
}
entity_is_valid_ptr :: proc(entity: ^Entity) -> bool {
	return entity != nil && entity_is_valid(entity^)
}
entity_init_core :: proc() {
	// make sure the zero entity has good defaults, so we don't crash on stuff like functions pointers
	entity_setup(&zero_entity, .NIL)
}

entity_get_all :: proc() -> []Handle {
	return g.scratch.all_entities
}

entity_get :: proc(handle: Handle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > g.entity_top_count {
		return &zero_entity, false
	}

	ent := &g.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
}

entity_clear_all :: proc() {
	for ent in g.scratch.all_entities {
		entity_destroy(entity_get(ent))
	}
}

entity_create :: proc(kind: EntityKind) -> ^Entity {

	index := -1
	if len(g.entity_free_list) > 0 {
		index = pop(&g.entity_free_list)
	}

	if index == -1 {
		assert(g.entity_top_count + 1 < MAX_ENTITIES, "ran out of entities, increase size")
		g.entity_top_count += 1
		index = g.entity_top_count
	}

	ent := &g.entities[index]
	ent.handle.index = index
	ent.handle.id = g.latest_entity_id + 1
	g.latest_entity_id = ent.handle.id
	entity_setup(ent, kind)
	fmt.assertf(ent.kind != nil, "entity %v needs to define a kind during setup", kind)

	return ent
}

entity_destroy :: proc(e: ^Entity) {
	append(&g.entity_free_list, e.handle.index)
	e^ = {}
}

entity_setup :: proc(e: ^Entity, kind: EntityKind) {
	// entity defaults
	e.scale = 1
	e.kind = kind
	e.created_on = rl.GetTime()

	switch kind {
	case .NIL:
	case .PLAYER:
		player_setup(e)
	}
}
