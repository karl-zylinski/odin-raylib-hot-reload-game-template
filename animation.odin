package game

import "core:log"

import rl "vendor:raylib"

Animation :: struct {
	texture: Texture,
	num_frames: int,
	current_frame: int,
	frame_timer: f32,
}

animation_create :: proc(tex: Texture, num_frames: int) -> Animation {
	return Animation {
		texture = tex,
		num_frames = num_frames,
	}
}

animation_update :: proc(a: ^Animation) {
	a.frame_timer -= rl.GetFrameTime()

	if a.frame_timer <= 0 {
		a.frame_timer = 0.2
		a.current_frame += 1

		if a.current_frame >= a.num_frames {
			a.current_frame = 0
		}
	}
}

animation_draw :: proc(a: Animation, pos: Vec2) {
	if a.num_frames == 0 {
		log.error("Animation has zero frames")
		return
	}

	w := f32(a.texture.width) / f32(a.num_frames)
	h := f32(a.texture.height)

	source := Rect {
		x = f32(a.current_frame) * w,
		y = 0,
		width = w,
		height = h,
	}

	draw_texture(a.texture, source, pos)
}