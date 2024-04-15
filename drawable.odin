package game

import "core:log"

DrawableOrigin :: enum {
	Center,
	BottomCenter,
}

DrawableRect :: struct {
	rect: Rect,
	color: Color,
}

DrawableTexture :: struct {
	texture: Texture,
	source: Rect,
	pos: Vec2,
	offset: Vec2,
}

Drawable :: union {
	DrawableTexture,
	DrawableRect,
}

DrawableArray :: [4096]Drawable

@(private="file")
drawables: ^DrawableArray
@(private="file")
num_drawables: int

drawables_init :: proc(d: ^DrawableArray) {
	drawables = d
}

drawables_slice :: proc() -> []Drawable {
	return drawables[:num_drawables]
}

drawables_reset :: proc() {
	num_drawables = 0
}

add_drawable :: proc(d: Drawable) {
	if num_drawables == len(drawables) {
		log.error("Out of drawbles")
		return
	}

	drawables[num_drawables] = d
	num_drawables += 1
}

draw_texture_pos :: proc(tex: Texture, pos: Vec2, origin: DrawableOrigin = .BottomCenter) {
	offset: Vec2

	switch origin {
		case .Center:
			offset = {f32(-tex.width)/2, f32(-tex.height)/2}
		case .BottomCenter:
			offset = {f32(-tex.width)/2, f32(-tex.height)}
	}

	add_drawable(DrawableTexture {
		texture = tex,
		pos = pos,
		offset = offset,
	})
}

draw_texture_rec :: proc(tex: Texture, source: Rect, pos: Vec2, origin: DrawableOrigin = .BottomCenter) {
	offset: Vec2

	switch origin {
		case .Center:
			offset = {f32(-source.width)/2, f32(-source.height)/2}
		case .BottomCenter:
			offset = {f32(-source.width)/2, f32(-source.height)}
	}

	add_drawable(DrawableTexture {
		texture = tex,
		source = source,
		pos = pos,
		offset = offset,
	})
}

draw_texture :: proc { draw_texture_pos, draw_texture_rec }

draw_rect :: proc(r: Rect, c: Color) {
	add_drawable(DrawableRect {
		rect = r,
		color = c,
	})
}