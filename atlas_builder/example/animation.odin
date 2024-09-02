// This implements animations using an atlased texture as defined in atlas.odin (which is generated
// before the code in this folder is built).
//
// These animations target a specific `Animation_Name` from atlas.odin. `animation_update` uses a
// timer to know when to switch to the next frame. It uses the duration in the texture, which may
// come from an aseprite frame.
//
// Use proc `animation_atlas_texture` to fetch the current frame's atlas texture, which you can
// then draw using:
// anim_texture := animation_atlas_texture(my_anim)
// rl.DrawTextureRec(atlas, anim_texture.rect, position, rl.WHITE)
//
// See main.odin for a more involved example of how to use the animation_atlas_texture proc.

package game

Animation :: struct {
	atlas_anim: Animation_Name,
	current_frame: Texture_Name,
	timer: f32,
}

animation_create :: proc(anim: Animation_Name) -> Animation {
	a := atlas_animations[anim]

	return {
		current_frame = a.first_frame,
		atlas_anim = anim,
		timer = atlas_textures[a.first_frame].duration,
	}
}

animation_update :: proc(a: ^Animation, dt: f32) -> bool {
	a.timer -= dt
	looped := false

	if a.timer <= 0 {
		a.current_frame = Texture_Name(int(a.current_frame) + 1)
		anim := atlas_animations[a.atlas_anim]

		if a.current_frame > anim.last_frame {
			a.current_frame = anim.first_frame
			looped = true
		}

		a.timer = atlas_textures[a.current_frame].duration
	}

	return looped
}

animation_length :: proc(anim: Animation_Name) -> f32 {
	l: f32
	aa := atlas_animations[anim]

	for i in aa.first_frame..=aa.last_frame {
		t := atlas_textures[i]
		l += t.duration
	}

	return l
}

animation_atlas_texture :: proc(anim: Animation) -> Atlas_Texture {
	return atlas_textures[anim.current_frame]
}