By Karl Zylinski, http://zylinski.se

Support me at https://www.patreon.com/karl_zylinski

# What's this?

This atlas builder looks into a 'textures' folder for pngs, ase and aseprite files and makes an atlas from those. It outputs both atlas.png and atlas.odin. The odin file you compile as part of your game. It contains metadata about where in the atlas the textures ended up.

Showcase & demo video: https://www.youtube.com/watch?v=u8Kt0Td76zI

The atlas builder can also split up tilesets and fonts and splat those out into the atlas. It detects if a texture is a tileset by checking if the name starts with `tileset_`.

A big benefit with using an atlas is that you can drastically lower the number of draw calls due to everything being in a single texture.

# Dependencies
The generator itself only uses core and vendor libs, plus an aseprite package, which is included.

As for `atlas.odin`, it has no dependencies. However, I use the types `Rect` and `Vec2` in `atlas.odin` file. Make sure you define them somehow in the same package as you use `atlas.odin` in. For example, if you use raylib:
```
Rect :: rl.Rectangle
Vec2 :: rl.Vector2
```
or like this if you don't use raylib:
```
// Names are not important in rect type, just the order of x, y, width and height.
Rect :: struct {
	x: f32,
	y: f32,
	width: f32,
	height: f32,
}
Vec2 :: [2]f32
```
Just make sure you have something along those lines the same package as this file (or change the generator code in `atlas_builder.odin` to use other type names).

# How to run the atlas builder
- In the root of this repository, create a folder called 'textures' and put .ase, .aseprite or .png files in it
- From the root of the template ropo, execute `odin run atlas_builder`
- `atlas.png` and `atlas.odin` are ouputted

Change `ATLAS_SIZE` in `atlas_builder.odin` to change the maximum width and height of the atlas.
Note: The final atlas is cropped to the actual contents inside it, it may be smaller than `ATLAS_SIZE`. Remove the `rl.ImageAlphaCrop(&atlas, 0)` line in `atlas_builder.odin` if you do not what this cropping.

# Loading the atlas

In your game load the atlas once. Here I put it in a globally accessible struct called `g_mem`:
```
g_mem.atlas = rl.LoadTexture(TEXTURE_ATLAS_FILENAME)
```


# Draw textures from atlas

Draw like this using Raylib:

```
rl.DrawTextureRec(g_mem.atlas, atlas_textures[.Bush].rect, position, rl.WHITE)
```
or
```
rl.DrawTexturePro(g_mem.atlas, atlas_textures[.Bush].rect, destination_rect, rl.WHITE)
```

This uses texture name "Bush" which will exist if there is a texture called `textures/bush.ase`. `atlas_textures` lives in atlas.odin.

There's also a `atlas_textures[.Bush].offset` you can add to your position. The offset is non-zero if there was empty pixels in the upper regions of the texture. This saves atlas-space, since it would have to write empty pixels otherwise! See the [animation examples](#animations) for how I use it.

# Atlas-based Raylib font

Set `FONT_FILENAME` and `LETTERS_IN_FONT` inside `atlas_builder.odin` before running the atlas builder.

Then in your game you create a font based on the letters in the atlas like this:

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

Here `atlas_glyphs` and `ATLAS_FONT_SIZE` exist within `atlas.odin`.

# Make Raylib draw shapes using atlas

Do this once at startup:

```
rl.SetShapesTexture(g_mem.atlas, shapes_texture_rect)
```

After this whenever you call `rl.DrawRectangleRec` or any of the the other shape drawing procs, then they will use the atlas as well, avoiding separate draw calls for shapes.


# Animations

There's an `atlas_animations` list. Any aseprite file that has more than one frame will be treated as an animation and added to that list. Also, tags within the ase file will result in separate animations. Each atlas animation entry knows which is the first and last texture in the animation. The animation update code then simply becomes to step to the next frame when necesarry. There's a duration on each Atlas_Texture struct that contains the duration of the frame as set in aseprite.

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

animation_draw :: proc(anim: Animation, pos: rl.Vector2) {
	if anim.current_frame == .None {
		return
	}

	texture := atlas_textures[anim.current_frame]
	
	// Note: The texture.offset may contain a non-zero offset. This offset occurs
	// when textures have some empty pixels in the upper regions. Instead of the
	// packer writing in those empty pixels (wasting space), it record how much
	// you need to offset your texture to compensate for the missing empty pixels.
	offset_pos := pos + {f32(texture.offset.x), f32(texture.offset.y)}

	rl.DrawTextureRec(g_mem.atlas, texture.rect, offset_pos, rl.WHITE)
}
```

create an animation using

```
anim := animation_create(.Some_Animation_Name) 
```
and save that animation somewhere. Update it each frame:

```
animation_update(&where_ever_you_put_the_anim, rl.GetFrameTime())
```

and finally draw the animation

```
animation_draw(where_ever_you_put_the_anim, position)
```

# Tilesets

If a texture name starts with `tileset_` then it will be treated as a tileset. In that case `atlas_tiles` contains the mapping from tile IDs the atlas rects.

The tile IDs are of the format `T0Y0X0`, `T0Y0X1` etc. I.e. just coordinates of which tile is which. You can check if a tile exists by doing `if atlas_tiles[some_tile_id] != {} { }`

Note: Set `TILE_SIZE` and `TILESET_WIDTH` in `atlas_builder.odin` to the correct values for your tileset.
