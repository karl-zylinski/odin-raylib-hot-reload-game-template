package game

texture_rect :: proc(tex: Texture, flip_x: bool) -> Rect {
	return {
		x = 0,
		y = 0,
		width = flip_x ? - f32(tex.width) : f32(tex.width),
		height = f32(tex.height),
	}
}
