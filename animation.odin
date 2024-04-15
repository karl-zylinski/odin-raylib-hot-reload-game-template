// This implements simple animations using sprite sheets. The texture in the
// `Animation` struct is assumed to contain a horizontal strip of the frames
// in the animation. Call `animation_update` to update and then call
// `animation_rect` when you wish to know the source rect to use in the texture
// With the source rect you can run rl.DrawTextureRec to draw the current frame.

package game

import "core:log"

Animation :: struct {
	texture: Texture,
	num_frames: int,
	current_frame: int,
	frame_timer: f32,
	frame_length: f32,
}

animation_create :: proc(tex: Texture, num_frames: int, frame_length: f32) -> Animation {
	return Animation {
		texture = tex,
		num_frames = num_frames,
		frame_length = frame_length,
		frame_timer = frame_length,
	}
}

animation_update :: proc(a: ^Animation, dt: f32) {
	a.frame_timer -= dt

	if a.frame_timer <= 0 {
		a.frame_timer = a.frame_length + a.frame_timer
		a.current_frame += 1

		if a.current_frame >= a.num_frames {
			a.current_frame = 0
		}
	}
}

animation_rect :: proc(a: Animation) -> Rect {
	if a.num_frames == 0 {
		log.error("Animation has zero frames")
		return RectEmpty
	}

	w := f32(a.texture.width) / f32(a.num_frames)
	h := f32(a.texture.height)

	return {
		x = f32(a.current_frame) * w,
		y = 0,
		width = w,
		height = h,
	}
}