By Karl Zylinski, http://zylinski.se -- Support me at https://www.patreon.com/karl_zylinski

**See the example folder for a sample program that generates and uses an atlas.**

# What's this?

This atlas builder looks into a 'textures' folder for pngs, ase and aseprite files and makes an atlas from those. It outputs both `atlas.png` and `atlas.odin`. The odin file you compile as part of your game. It contains metadata about where in the atlas the textures ended up.

Animated aseprite files are supported, animations get their own metadata in `atlas.odin`.

The builder can load a font and bake characters into the atlas.

The atlas builder can also split up tilesets and fonts and splat those out into the atlas. It detects if a texture is a tileset by checking if the name starts with `tileset_`.

A big benefit with using an atlas is that you can drastically lower the number of draw calls due to everything being in a single texture.

Showcase & demo video: https://www.youtube.com/watch?v=u8Kt0Td76zI

# Dependencies
The generator itself only uses core and vendor libs, plus an aseprite package by blob1807, which is included.

`atlas.odin` uses the type `Rect` which defines a rectangle. Make sure you define such a type in the package where you are going to use `atlas.odin`. For example, if you use Raylib:
```
Rect :: rl.Rectangle
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
```

# How to run the atlas builder

See the README.md in the `example` folder. But in short:
- Run this package.
- It looks for `textures` folder and a `font.ttf` file in the current working directory.
- `atlas.png` and `atlas.odin` are ouputted
- Those files can be used within your game to do efficent atlased drawing. See the example for more info.

# Configuration

There are a few constants at the top of `atlas_builder.odin`:

- `ATLAS_SIZE`: Maximum size of `atlas.png`.
- `ATLAS_PNG_OUTPUT_PATH`: Path to output the atlas PNG to
- `ATLAS_ODIN_OUTPUT_PATH`: Path to output the atlas Odin metadata file to
- `ATLAS_CROP`: If atlas should be cropped after generation. Default: true
- `TILESET_WIDTH`: If you have any texture prefixed with `tileset_`, it will be treated as a tileset. This setting says how many tiles wide it is.
- `TILESET_SIZE`: How many pixels each tile takes in the tileset
- `PACKAGE_NAME`: The package name to use at the top of the `atlas.odin` file.
- `TEXTURES_DIR`: The folder in which to look for textures to put into atlas.
- `LETTERS_IN_FONT`: The letters to extract from the font.
- `FONT_FILENAME`: The filename of the font to extract letters from.
- `FONT_SIZE`: The font size of letters extracted from font

# Loading the atlas

In your game load the atlas once, for example:
```
atlas = rl.LoadTexture(TEXTURE_ATLAS_FILENAME)
```

# Draw textures from atlas

Draw like this using Raylib:

```
rl.DrawTextureRec(atlas, atlas_textures[.Bush].rect, position, rl.WHITE)
```
or
```
rl.DrawTexturePro(atlas, atlas_textures[.Bush].rect, destination_rect, rl.WHITE)
```

This uses texture name "Bush" which will exist if there is a texture called `textures/bush.ase`. `atlas_textures` lives in `atlas.odin`.

There's also four offsets on `atlas_textures[.Bush]`: `offset_top`, `offset_right`, `offset_bottom` and `offset_left`. The offsets records the distance between the pixels in the atlas and the edge of the original document in the image editing software. Since the atlas is tightly packed, any empty pixels are removed. These offsets can be used to correct for that removal. This saves atlas-space, since it would have to write empty pixels otherwise! Normally you'd need to add `{offset_left, offset_top}` to your position, but if you flip the texture in X or Y direction then you might need the `offset_right` or `offset_bottom`. See the [animation examples](#animations) for exampl I use it.

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
	texture = atlas,
	recs = raw_data(font_rects),
	glyphs = raw_data(glyphs),
}
```

Here `atlas_glyphs` and `ATLAS_FONT_SIZE` exist within `atlas.odin`.

# Make Raylib draw shapes using atlas

Do this once at startup:

```
rl.SetShapesTexture(atlas, shapes_texture_rect)
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
	
	// The texture has four offset fields: offset_top, right, bottom and left. The offsets records
	// the distance between the pixels in the atlas and the edge of the original document in the
	// image editing software. Since the atlas is tightly packed, any empty pixels are removed.
	// These offsets can be used to correct for that removal.
	//
	// This can be especially obvious in animations where different frames can have different
	// amounts of empty pixels around it. By adding the offsets everything will look OK.
	//
	// If you ever flip the animation in X or Y direction, then you might need to add the right or
	// bottom offset instead.
	offset_pos := pos + {texture.offset_left, texture.offset_top}

	rl.DrawTextureRec(atlas, texture.rect, offset_pos, rl.WHITE)
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
