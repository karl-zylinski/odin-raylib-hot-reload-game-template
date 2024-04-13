package game

Vec2i :: [2]int
Vec2 :: [2]f32

vec2_from_vec2i :: proc(p: Vec2i) -> Vec2 {
	return { f32(p.x), f32(p.y) }
}
