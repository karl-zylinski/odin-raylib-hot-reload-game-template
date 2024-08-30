By Karl Zylinski, http://zylinski.se

Support me at https://www.patreon.com/karl_zylinski

# What's this?

This atlas builder looks into a 'textures' folder for pngs, ase and aseprite files and makes an atlas from those. It outputs both atlas.png and atlas.odin. The odin file you compile as part of your game. It contains metadata about where in the atlas the textures ended up.

The atlas builder can also split up tilesets and fonts and splat those out into the atlas. It detects if a texture is a tileset by checking if the name starts with `tileset_`. Search for `FONT_FILENAME` and `tileset_` in `atlas_builder.odin` to see how that works. Note: Set TILE_SIZE and TILESET_WIDTH to the correct values if you use a tileset.

A big benefit with using an atlas is that you can drastically lower the number of draw calls due to everything being in a single texture.

Note: I use the types `Rect` and `Vec2i` in the outputted `atlas.odin` file. They should be defined in your code as:
```
Rect :: rl.Rectangle
Vec2i :: [2]int
```
TODO: Should I just use `Vec2 :: rl.Vector2` instead of an integer vector?


# How to run the atlas builder
- In the root of the template repo, a textures folder and put .ase, .aseprite or .png files in it
- From the root of the template ropo, execute `odin run atlas_builder`
- `atlas.png` and `atlas.odin` are ouputted


# Loading the atlas

In your game load the atlas once (here I put it in a globally accessible struct called g_mem):
```
g_mem.atlas = rl.LoadTexture(TEXTURE_ATLAS_FILENAME)
```


# Draw textures from atlas

Draw like this using Raylib. This uses texture name "Bush" which will exist if there is a texture called `textures/bush.ase` (or .aseprite or .png):

```
rl.DrawTextureRec(g_mem.atlas, atlas_textures[.Bush].rect, position, rl.WHITE)
rl.DrawTexturePro(g_mem.atlas, atlas_textures[.Bush].rect, destination_rect, rl.WHITE)
```

(atlas_textures lives in atlas.odin)

There's also a atlas_textures[.Bush].offset you can add to your position. The offset is non-zero if there was empty pixels in the upper regions of the texture. This saves atlas-space, since it would have to write empty pixels otherwise!


# How to create a Raylib font based on the letters in the atlas

```
num_glyphs := len(atlas_glyphs)
font_rects := make([]Rect, num_glyphs)
glyphs := make([]rl.GlyphInfo, num_glyphs)

for ag, idx in atlas_glyphs {
	font_rects[idx] = ag.rect
	glyphs[idx] = {
		value = ag.value,
		offsetX = i32(ag.offset_x),
		offsetY = i32(ag.offset_y),
		advanceX = i32(ag.advance_x),
	}
} 

font := rl.Font {
	baseSize = ATLAS_FONT_SIZE,
	glyphCount = i32(num_glyphs),
	glyphPadding = 0,
	texture = g_mem.atlas,
	recs = raw_data(font_rects),
	glyphs = raw_data(glyphs),
}
```

# How to make Raylib shapes drawing use atlas

```
rl.SetShapesTexture(g_mem.atlas, shapes_texture_rect)
```

After this whenever you call `rl.DrawRectangleRec` or any of the the other shape drawing procs, then they will use the atlas as well, avoiding separate draw calls for shapes.


# Animations

There's an `atlas_animations` list. Any aseprite file that has more than one frame will be treated as an animation and added to that list. Each atlas animation entry knows which is the first and last texture in the animation. The animation update code then simply becomes to step to the next frame when necesarry. There's a duration on each Atlas_Texture struch that can will contain the value of the duration of the frame as set in aseprite.

Here's an implementation of how to animate using the atlased animations:

```
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

animation_draw :: proc(anim: Animation_Name, pos: rl.Vector2) -> f32 {
	if anim.current_frame == .None {
		return
	}

	rl.DrawTextureRec(g_mem.atlas, atlas_textures[anim.current_frame].rect, pos, rl.WHITE)
}
```

# Tilesets

If a texture name starts with `tileset_` then it will be treated as a tileset. In that case `atlas_tiles` contains the mapping from tile IDs the atlas rects.

The tile IDs are of the format `T0Y0X0`, `T0Y0X1` etc. I.e. just coordinates of which tile is which. You can check if a tile exists by doing `if atlas_tiles[some_tile_id] != {} { }`