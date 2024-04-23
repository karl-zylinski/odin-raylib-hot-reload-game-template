// procs for modifying and managing rects

package game

import rl "vendor:raylib"

Rect :: rl.Rectangle

RectEmpty :: Rect{}

split_rect_top :: proc(r: Rect, y: f32, m: f32) -> (top, bottom: Rect) {
	top = r
	bottom = r
	top.y += m
	top.height = y
	bottom.y += y + m
	bottom.height -= y + m
	return
}

split_rect_left :: proc(r: Rect, x: f32, m: f32) -> (left, right: Rect) {
	left = r
	right = r
	left.width = x
	right.x += x + m
	right.width -= x +m
	return
}

split_rect_bottom :: proc(r: rl.Rectangle, y: f32, m: f32) -> (top, bottom: rl.Rectangle) {
	top = r
	top.height -= y + m
	bottom = r
	bottom.y = top.y + top.height + m
	bottom.height = y
	return
}

split_rect_right :: proc(r: Rect, x: f32, m: f32) -> (left, right: Rect) {
	left = r
	right = r
	right.width = x
	left.width -= x + m
	right.x = left.x + left.width
	return
}

cut_rect_top :: proc(r: ^Rect, y: f32, m: f32) -> Rect {
	res := r^
	res.y += m
	res.height = y
	r.y += y + m
	r.height -= y + m
	return res
}

cut_rect_bottom :: proc(r: ^Rect, h: f32, m: f32) -> Rect {
	res := r^
	res.height = h
	res.y = r.y + r.height - h - m
	r.height -= h + m
	return res
}

cut_rect_left :: proc(r: ^Rect, x, m: f32) -> Rect {
	res := r^
	res.x += m
	res.width = x
	r.x += x + m
	r.width -= x + m
	return res
}

cut_rect_right :: proc(r: ^Rect, w, m: f32) -> Rect {
	res := r^
	res.width = w
	res.x = r.x + r.width - w - m
	r.width -= w + m
	return res
}

rect_middle :: proc(r: Rect) -> Vec2 {
	return {
		r.x + f32(r.width) * 0.5,
		r.y + f32(r.height) * 0.5,
	}
}

inset_rect :: proc(r: Rect, x: f32, y: f32) -> Rect {
	return {
		r.x + x,
		r.y + y,
		r.width - x * 2,
		r.height - y * 2,
	}
}

rect_add_pos :: proc(r: Rect, p: Vec2) -> Rect {
	return {
		r.x + p.x,
		r.y + p.y,
		r.width,
		r.height,
	}
}

mouse_in_rect :: proc(r: Rect) -> bool {
	return rl.CheckCollisionPointRec(rl.GetMousePosition(), r)
}

mouse_in_world_rect :: proc(r: Rect, camera: rl.Camera2D) -> bool {
	return rl.CheckCollisionPointRec(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera), r)
}