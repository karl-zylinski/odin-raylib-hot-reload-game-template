package game
import rl "vendor:raylib"

player_setup :: proc(player: ^Entity) {
	player.animation = init_player_run_animation()
	player.collider.rectangle = rl.Rectangle {
		x = 10,
		y = 10,
	}
	player.on_update = player_update
	player.on_draw = player_draw
}

player_update :: proc(player: ^Entity) {

	player.velocity.y = 0
	player.velocity.y += 10

	// WARNING: nothing goes after this line
	player.pos += player.velocity * rl.GetFrameTime()
}
player_draw :: proc(player: Entity) {
	entity_draw_default(player)
}
init_player_run_animation :: proc() -> Animation {
	return Animation {
		texture = g.textures.player_run,
		frame_count = 4,
		frame_timer = 0,
		current_frame = 0,
		frame_length = 0.1,
		kind = .IDLE,
	}
}
