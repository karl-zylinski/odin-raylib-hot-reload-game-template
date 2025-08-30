package game

import "core:fmt"
import rl "vendor:raylib"

Animation :: struct {
	kind:          AnimationKind,
	texture:       rl.Texture2D,
	frame_count:   int,
	frame_timer:   f32,
	current_frame: int,
	frame_length:  f32,
	flip_x:        bool,
}

AnimationKind :: enum {
	NIL,
	IDLE,
}

animate :: proc(entity: ^Entity) {
	if entity.animation.kind == .NIL {
		return
	}
	entity.animation.frame_timer += rl.GetFrameTime()

	if entity.animation.frame_timer > entity.animation.frame_length {
		entity.animation.current_frame += 1
		entity.animation.frame_timer = 0

		if entity.animation.current_frame == entity.animation.frame_count {
			entity.animation.current_frame = 0
		}
	}
}

get_source_rect :: proc(animation: Animation) -> rl.Rectangle {
	fmt.assertf(animation.frame_count > 0, "animation needs atleast 1 frame", animation)
	texture_width := f32(animation.texture.width / i32(animation.frame_count))
	texture_height := f32(animation.texture.height)
	x := texture_width * f32(animation.current_frame)

	source_rect := rl.Rectangle{x, 0, texture_width, texture_height}

	return source_rect
}
