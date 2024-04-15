package game

import rl "vendor:raylib"
import "core:slice"

Texture :: rl.Texture
Color :: rl.Color

texture_rect :: proc(tex: Texture, flip_x: bool) -> Rect {
	return {
		x = 0,
		y = 0,
		width = flip_x ? - f32(tex.width) : f32(tex.width),
		height = f32(tex.height),
	}
}

load_premultiplied_alpha_ttf_from_memory :: proc(file_data: []byte, font_size: int) -> rl.Font {
	font := rl.Font {
		baseSize = i32(font_size),
		glyphCount = 95,
	}

	font.glyphs = rl.LoadFontData(&file_data[0], i32(len(file_data)), font.baseSize, {}, font.glyphCount, .DEFAULT)

	if font.glyphs != nil {
		font.glyphPadding = 4

		atlas := rl.GenImageFontAtlas(font.glyphs, &font.recs, font.glyphCount, font.baseSize, font.glyphPadding, 0)
		atlas_u8 := slice.from_ptr((^u8)(atlas.data), int(atlas.width*atlas.height*2))

		for i in 0..<atlas.width*atlas.height {
			a := atlas_u8[i*2 + 1]
			v := atlas_u8[i*2]
			atlas_u8[i*2] = u8(f32(v)*(f32(a)/255))
		}

		font.texture = rl.LoadTextureFromImage(atlas)
		rl.SetTextureFilter(font.texture, .BILINEAR)

		// Update glyphs[i].image to use alpha, required to be used on ImageDrawText()
		for i in 0..<font.glyphCount {
			rl.UnloadImage(font.glyphs[i].image)
			font.glyphs[i].image = rl.ImageFromImage(atlas, font.recs[i])
		}
		//TRACELOG(LOG_INFO, "FONT: Data loaded successfully (%i pixel size | %i glyphs)", font.baseSize, font.glyphCount);

		rl.UnloadImage(atlas)
	} else {
		font = rl.GetFontDefault()
	}

	return font
}