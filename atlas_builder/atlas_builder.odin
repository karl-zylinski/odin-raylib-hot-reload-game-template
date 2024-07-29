// This atlas builder looks into a 'textures' folder for pngs, ase and aseprite files and makes an atlas
// from those. It outputs both atlas.png and atlas.odin. The odin file you compile as part of your game
// it contains metadata about where in the atlas the stuff is.
//
// The atlas builder can also split up tilesets and fonts and splat those out into the atlas. Look for
// the code below that processes `.ttf` and images with filenames that start with `tileset`.

package ase_to_atlas

import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/slashpath"
import "core:slice"
import "core:strings"
import "core:time"
import "core:unicode/utf8"
import "core:image/png"
import "vendor:stb/rect_pack"
import ase "aseprite"
import rl "vendor:raylib"

dir_path_to_file_infos :: proc(path: string) -> []os.File_Info {
	d, derr := os.open(path, os.O_RDONLY)
	if derr != 0 {
		panic("open failed")
	}
	defer os.close(d)

	{
		file_info, ferr := os.fstat(d)
		defer os.file_info_delete(file_info)

		if ferr != 0 {
			panic("stat failed")
		}
		if !file_info.is_dir {
			panic("not a directory")
		}
	}

	file_infos, _ := os.read_dir(d, -1)
	return file_infos
}

Vec2i :: [2]int

Atlas_Texture_Rect :: struct {
	rect: rl.Rectangle,
	size: Vec2i,
	offset: Vec2i,
	name: string,
	duration: f32,
}

Atlas_Tile_Rect :: struct {
	rect: rl.Rectangle,
	coord: Vec2i,
}

Atlas_Glyph :: struct {
	rect: rl.Rectangle,
	glyph: rl.GlyphInfo,
}

asset_name :: proc(path: string) -> string {
	return fmt.tprintf("%s", strings.to_ada_case(slashpath.name(slashpath.base(path)), context.temp_allocator))
}

Texture_Data :: struct {
	source_size: Vec2i,
	source_offset: Vec2i,
	document_size: Vec2i,
	offset: Vec2i,
	name: string,
	pixels_size: Vec2i,
	pixels: []rl.Color,
	duration: f32,
	is_tile: bool,
	tile_coord: Vec2i,
}

rect_intersect :: proc(r1, r2: rl.Rectangle) -> rl.Rectangle {
	x1 := max(r1.x, r2.x)
	y1 := max(r1.y, r2.y)
	x2 := min(r1.x + r1.width, r2.x + r2.width)
	y2 := min(r1.y + r1.height, r2.y + r2.height)
	if x2 < x1 { x2 = x1 }
	if y2 < y1 { y2 = y1 }
	return {x1, y1, x2 - x1, y2 - y1}
}

TILESET_WIDTH :: 10
TILE_SIZE :: 10

Tileset :: struct {
	pixels: []rl.Color,
	pixels_size: Vec2i,
	visible_pixels_size: Vec2i,
	offset: Vec2i,
}

load_tileset :: proc(filename: string, t: ^Tileset) {
	data, data_ok := os.read_entire_file(filename)

	if !data_ok {
		fmt.printf("Failed loading tileset %v\n", filename)
		return
	}

	defer delete(data)
	doc: ase.Document
	defer ase.destroy_doc(&doc)

	_, umerr := ase.unmarshal(data[:], &doc)
	if umerr != nil {
		fmt.println(umerr)
		return
	}

	indexed := doc.header.color_depth == .Indexed

	for f in doc.frames {
		palette: ase.Palette_Chunk
		collision_layer := -1
		layers := 0

		for c in f.chunks {
			if p, ok := c.(ase.Palette_Chunk); ok {
				palette = p
			} else if l, ok := c.(ase.Layer_Chunk); ok {
				if l.name == "collision" {
					collision_layer = layers
				}

				layers += 1
			}
		}

		if indexed && len(palette.entries) == 0 {
			fmt.println("Document is indexed, but found no palette!")
			continue
		}

		for c in f.chunks {
			#partial switch cv in c {
				case ase.Cel_Chunk:
					if cl, ok := cv.cel.(ase.Com_Image_Cel); ok {
						if int(cv.layer_index) == collision_layer {
							break
						}

						if indexed {
							t.pixels = make([]rl.Color, int(cl.width) * int(cl.height))
							for p, idx in cl.pixel {
								t.pixels[idx] = rl.Color(palette.entries[u32(p)].color.abgr)
							}
						} else {
							t.pixels = slice.clone(transmute([]rl.Color)(cl.pixel))
						}

						t.offset = {int(cv.x), int(cv.y)}
						t.pixels_size = {int(cl.width), int(cl.height)}
						t.visible_pixels_size = {int(doc.header.width), int(doc.header.height)}
					}
			}
		}
	}
}

Animation :: struct {
	name: string,
	first_texture: string,
	last_texture: string,
}

load_ase_texture_data :: proc(filename: string, textures: ^[dynamic]Texture_Data, animations: ^[dynamic]Animation) {
	data, data_ok := os.read_entire_file(filename)

	if !data_ok {
		return
	}

	defer delete(data)

	doc: ase.Document
	defer ase.destroy_doc(&doc)

	_, umerr := ase.unmarshal(data[:], &doc)
	if umerr != nil {
		fmt.println(umerr)
		return
	}

	base_name := asset_name(filename)
	frame_idx := 0
	animated := len(doc.frames) > 1
	indexed := doc.header.color_depth == .Indexed

	for f in doc.frames {
		duration: f32 = f32(f.header.duration)/1000.0
		palette: ase.Palette_Chunk
		collision_layer := -1

		layers := 0

		for c in f.chunks {
			if p, ok := c.(ase.Palette_Chunk); ok {
				palette = p
			} else if l, ok := c.(ase.Layer_Chunk); ok {
				if l.name == "collision" {
					collision_layer = layers
				}

				layers += 1
			}
		}

		if indexed && len(palette.entries) == 0 {
			fmt.println("Document is indexed, but found no palette!")
			continue
		}

		for c in f.chunks {
			#partial switch cv in c {
				case ase.Cel_Chunk:
					if cl, ok := cv.cel.(ase.Com_Image_Cel); ok {
						td := Texture_Data {
							source_size = {int(cl.width), int(cl.height)},
							pixels_size = {int(cl.width), int(cl.height)},
							document_size = {int(doc.header.width), int(doc.header.height)},
							offset = {int(cv.x), int(cv.y)},
							duration = duration,
							name = animated ? fmt.tprint(base_name, frame_idx, sep = "") : base_name,
						}

						if indexed {
							td.pixels = make([]rl.Color, int(cl.width) * int(cl.height))
							for p, idx in cl.pixel {
								td.pixels[idx] = rl.Color(palette.entries[u32(p)].color.abgr)
							}
						} else {
							td.pixels = slice.clone(transmute([]rl.Color)(cl.pixel))
						}

						cel_rect := rl.Rectangle {
							f32(cv.x),
							f32(cv.y),
							f32(cl.width),
							f32(cl.height),
						}

						document_rect := rl.Rectangle {
							0, 0,
							f32(doc.header.width), f32(doc.header.height),
						}

						visible_rect := rect_intersect(document_rect, cel_rect)

						if visible_rect.width != cel_rect.width || visible_rect.height != cel_rect.height {
							from := rl.Image {
								data = raw_data(td.pixels),
								width = i32(cl.width),
								height = i32(cl.height),
								mipmaps = 1,
								format = .UNCOMPRESSED_R8G8B8A8,
							}

							visible_pixels := make([]rl.Color, int(visible_rect.width * visible_rect.height))

							to := rl.Image {
								data = raw_data(visible_pixels),
								width = i32(visible_rect.width),
								height = i32(visible_rect.height),
								mipmaps = 1,
								format = .UNCOMPRESSED_R8G8B8A8,
							}

							source := visible_rect
							source.x -= cel_rect.x
							source.y -= cel_rect.y 
							dest := visible_rect
							dest.x += min(document_rect.x - cel_rect.x, 0)
							dest.y += min(document_rect.y - cel_rect.y, 0)

							rl.ImageDraw(&to, from, source, dest, rl.WHITE)

							td.pixels = visible_pixels
							td.source_size = {int(visible_rect.width), int(visible_rect.height)}
							td.pixels_size = td.source_size
							td.offset = {int(visible_rect.x), int(visible_rect.y)}
						}

						append(textures, td)

						frame_idx += 1
					}
			}
		}
	}

	if animated && frame_idx > 1 {
		a := Animation {
			name = base_name,
			first_texture = fmt.tprint(base_name, 0, sep = ""),
			last_texture = fmt.tprint(base_name, frame_idx - 1, sep = ""),
		}

		append(animations, a)
	}
}

load_png_texture_data :: proc(filename: string, textures: ^[dynamic]Texture_Data) {
	data, data_ok := os.read_entire_file(filename)

	if !data_ok {
		fmt.printf("Failed loading tileset %v\n", filename)
		return
	}

	defer delete(data)

	img, err := png.load_from_bytes(data)

	if err != nil {
		fmt.println(err)
		return
	}

	defer png.destroy(img)

	if img.depth != 8 && img.channels != 4 {
		fmt.println("Only 8 bpp, 4 channels PNG supported (this can probably be fixed by doing some work in `load_png_texture_data`")
		return
	}

	td := Texture_Data {
		source_size = {img.width, img.height},
		pixels_size = {img.width, img.height},
		document_size = {img.width, img.height},
		duration = 0,
		name = asset_name(filename),
		pixels = slice.clone(transmute([]rl.Color)(img.pixels.buf[:])),
	}

	append(textures, td)
}

ATLAS_SIZE :: 512

LETTERS_IN_FONT :: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890?&.,"

main :: proc() {
	textures: [dynamic]Texture_Data
	animations: [dynamic]Animation

	file_infos := dir_path_to_file_infos("textures")

	slice.sort_by(file_infos, proc(i, j: os.File_Info) -> bool {
		return time.diff(i.creation_time, j.creation_time) > 0
	})

	tileset: Tileset

	for fi in file_infos {
		is_ase := strings.has_suffix(fi.name, ".ase") || strings.has_suffix(fi.name, ".aseprite")
		is_png := strings.has_suffix(fi.name, ".png")
		if is_ase || is_png {
			path := fmt.tprintf("textures/%s", fi.name)
			if strings.has_prefix(fi.name, "tileset") {
				load_tileset(path, &tileset)
			} else if is_ase {
				load_ase_texture_data(path, &textures, &animations)	
			} else if is_png {
				load_png_texture_data(path, &textures)
			}
		}
	}

	rc: rect_pack.Context
	rc_nodes: [ATLAS_SIZE]rect_pack.Node
	rect_pack.init_target(&rc, ATLAS_SIZE, ATLAS_SIZE, raw_data(rc_nodes[:]), ATLAS_SIZE)

	letters := utf8.string_to_runes(LETTERS_IN_FONT)
	num_letters := len(letters)
	FONT_SIZE :: 8*4

	pack_rects: [dynamic]rect_pack.Rect
	glyphs: [^]rl.GlyphInfo

	PackRectType :: enum {
		Texture,
		Glyph,
		Tile,
		ShapesTexture,
	}

	make_pack_rect_id :: proc(id: i32, type: PackRectType) -> i32 {
		t := u32(type)
		t <<= 29
		t |= u32(id)
		return i32(t)
	}

	make_tile_id :: proc(x, y: int) -> i32 {
		id: i32 = i32(x)
		id <<= 13
		return id | i32(y)
	}

	idx_from_rect_id :: proc(id: i32) -> int {
		return int((u32(id) << 3)>>3)
	}

	x_y_from_tile_id :: proc(id: i32) -> (x, y: int) {
		id_type_stripped := idx_from_rect_id(id)
		return int(id_type_stripped >> 13), int((u32(id_type_stripped)<<19)>>19)
	}

	rect_id_type :: proc(i: i32) -> PackRectType {
		return PackRectType(i >> 29)
	}

	if font_data, ok := os.read_entire_file("easvhs.ttf"); ok {
		glyphs = rl.LoadFontData(&font_data[0], i32(len(font_data)), FONT_SIZE, raw_data(letters), i32(num_letters), .BITMAP)

		for i in 0..<len(letters) {
			g := glyphs[i]

			append(&pack_rects, rect_pack.Rect {
				id = make_pack_rect_id(i32(i), .Glyph),
				w = rect_pack.Coord(g.image.width) + 1,
				h = rect_pack.Coord(g.image.height) + 1,
			})
		}
	}

	for t, idx in textures {
		append(&pack_rects, rect_pack.Rect {
			id = make_pack_rect_id(i32(idx), .Texture),
			w = rect_pack.Coord(t.source_size.x) + 1,
			h = rect_pack.Coord(t.source_size.y) + 1,
		})
	}

	if tileset.pixels_size.x != 0 && tileset.pixels_size.y != 0 {
		assert(tileset.pixels_size.x + tileset.offset.x >= TILESET_WIDTH * TILE_SIZE, "Tileset texture too narrow")
		h := tileset.visible_pixels_size.y / TILE_SIZE
		top_left: rl.Vector2 = {-f32(tileset.offset.x), -f32(tileset.offset.y)}

		t_img := rl.Image {
			data = raw_data(tileset.pixels),
			width = i32(tileset.pixels_size.x),
			height = i32(tileset.pixels_size.y),
			format = .UNCOMPRESSED_R8G8B8A8,
		}
		
		for x in 0 ..<TILESET_WIDTH {
			for y in 0..<h {
				tx := f32(TILE_SIZE * x) + top_left.x
				ty := f32(TILE_SIZE * y) + top_left.y

				all_blank := true
				for txx in tx..<tx+TILE_SIZE {
					for tyy in ty..<ty+TILE_SIZE {
						if rl.GetImageColor(t_img, i32(txx), i32(tyy)) != rl.BLANK {
							all_blank = false
							break
						}
					}
				}

				if all_blank {
					continue
				}

				append(&pack_rects, rect_pack.Rect {
					id = make_pack_rect_id(make_tile_id(x, y), .Tile),
					w = 19,
					h = 19,
				})
			}
		}
	}

	append(&pack_rects, rect_pack.Rect {
		id = make_pack_rect_id(0, .ShapesTexture),
		w = 11,
		h = 11,
	})

	rect_pack_res := rect_pack.pack_rects(&rc, raw_data(pack_rects), i32(len(pack_rects)))

	if rect_pack_res != 1 {
		fmt.println("failed to pack some rects")
	}

	atlas := rl.GenImageColor(ATLAS_SIZE, ATLAS_SIZE, rl.BLANK)
	atlas_textures: [dynamic]Atlas_Texture_Rect
	atlas_tiles: [dynamic]Atlas_Tile_Rect

	atlas_glyphs: [dynamic]Atlas_Glyph
	shapes_texture_rect: rl.Rectangle

	for rp in pack_rects {
		type := rect_id_type(rp.id)

		switch type {
		case .ShapesTexture:
			shapes_texture_rect = rl.Rectangle {f32(rp.x), f32(rp.y), 10, 10}
			rl.ImageDrawRectangleRec(&atlas, shapes_texture_rect, rl.WHITE)
		case .Texture:
			idx := idx_from_rect_id(rp.id)

			t := textures[idx]

			t_img := rl.Image {
				data = raw_data(t.pixels),
				width = i32(t.pixels_size.x),
				height = i32(t.pixels_size.y),
				format = .UNCOMPRESSED_R8G8B8A8,
			}

			source := rl.Rectangle {f32(t.source_offset.x), f32(t.source_offset.y), f32(t.source_size.x), f32(t.source_size.y)}
			dest := rl.Rectangle {f32(rp.x), f32(rp.y), source.width, source.height}
			rl.ImageDraw(&atlas, t_img, source, dest, rl.WHITE)

			ar := Atlas_Texture_Rect {
				rect = dest,
				size = t.document_size,
				offset = t.offset,
				name = t.name,
				duration = t.duration,
			}

			append(&atlas_textures, ar)	
		case .Glyph:
			idx := idx_from_rect_id(rp.id)
			g := glyphs[idx]
			img_grayscale := g.image

			grayscale := transmute([^]u8)(img_grayscale.data)
			img_pixels := make([]rl.Color, img_grayscale.width*img_grayscale.height)

			for i in 0..<img_grayscale.width*img_grayscale.height {
				a := grayscale[i]
				img_pixels[i].r = 255
				img_pixels[i].g = 255
				img_pixels[i].b = 255
				img_pixels[i].a = a
			}

			img := img_grayscale

			img.data = raw_data(img_pixels)
			img.format = .UNCOMPRESSED_R8G8B8A8

			source := rl.Rectangle {0, 0, f32(img.width), f32(img.height)}
			dest := rl.Rectangle {f32(rp.x), f32(rp.y), source.width, source.height}

			rl.ImageDraw(&atlas, img, source, dest, rl.WHITE)

			ag := Atlas_Glyph {
				rect = dest,
				glyph = g,
			}

			append(&atlas_glyphs, ag)
		case .Tile:
			ix, iy := x_y_from_tile_id(rp.id)

			x := f32(TILE_SIZE * ix)
			y := f32(TILE_SIZE * iy)

			top_left: rl.Vector2 = {-f32(tileset.offset.x), -f32(tileset.offset.y)}

			t_img := rl.Image {
				data = raw_data(tileset.pixels),
				width = i32(tileset.pixels_size.x),
				height = i32(tileset.pixels_size.y),
				format = .UNCOMPRESSED_R8G8B8A8,
			}
			
			source := rl.Rectangle {x + top_left.x, y + top_left.y, TILE_SIZE, TILE_SIZE}
			dest := rl.Rectangle {f32(rp.x) + 1, f32(rp.y) + 1, source.width, source.height}
			rl.ImageDraw(&atlas, t_img, source, dest, rl.WHITE)

			// Add padding lines

			ts :: TILE_SIZE
			// Top
			{
				psource := rl.Rectangle {
					source.x,
					source.y,
					ts,
					1,
				}

				pdest := rl.Rectangle {
					dest.x,
					dest.y - 1,
					ts,
					1,
				}

				rl.ImageDraw(&atlas, t_img, psource, pdest, rl.WHITE)
			}

			// Bottom
			{
				psource := rl.Rectangle {
					source.x,
					source.y + ts -1,
					ts,
					1,
				}

				pdest := rl.Rectangle {
					dest.x,
					dest.y + ts,
					ts,
					1,
				}

				rl.ImageDraw(&atlas, t_img, psource, pdest, rl.WHITE)
			}

			// Left
			{
				psource := rl.Rectangle {
					source.x,
					source.y,
					1,
					ts,
				}
				
				pdest := rl.Rectangle {
					dest.x - 1,
					dest.y,
					1,
					ts,
				}

				rl.ImageDraw(&atlas, t_img, psource, pdest, rl.WHITE)
			}

			// Right
			{
				psource := rl.Rectangle {
					source.x + ts - 1,
					source.y,
					1,
					ts,
				}
				
				pdest := rl.Rectangle {
					dest.x + ts,
					dest.y,
					1,
					ts,
				}

				rl.ImageDraw(&atlas, t_img, psource, pdest, rl.WHITE)
			}

			at := Atlas_Tile_Rect {
				rect = dest,
				coord = {ix, iy},
			}

			append(&atlas_tiles, at)
		}
	}

	rl.ExportImage(atlas, "atlas.png")

	f, _ := os.open("atlas.odin", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	defer os.close(f)

	fmt.fprintln(f, "package game")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "TextureName :: enum {")
	fmt.fprint(f, "\tNone,\n")
	for r in atlas_textures {
		fmt.fprintf(f, "\t%s,\n", r.name)
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "AtlasTexture :: struct {")
	fmt.fprintln(f, "\trect: Rect,")
	fmt.fprintln(f, "\toffset: Vec2i,")
	fmt.fprintln(f, "\tdocument_size: Vec2i,")
	fmt.fprintln(f, "\tduration: f32,")
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "atlas_textures: [TextureName]AtlasTexture = {")
	fmt.fprintln(f, "\t.None = {},")

	for r in atlas_textures {
		fmt.fprintf(f, "\t.%s = {{ rect = {{%v, %v, %v, %v}}, offset = {{%v, %v}}, document_size = {{%v, %v}}, duration = %f}},\n", r.name, r.rect.x, r.rect.y, r.rect.width, r.rect.height, r.offset.x, r.offset.y, r.size.x, r.size.y, r.duration)
	}

	fmt.fprintln(f, "}\n")

	fmt.fprintln(f, "Atlas_Glyph :: struct {")
	fmt.fprintln(f, "\trect: Rect,")
	fmt.fprintln(f, "\tvalue: rune,")
	fmt.fprintln(f, "\toffset_x: int,")
	fmt.fprintln(f, "\toffset_y: int,")
	fmt.fprintln(f, "\tadvance_x: int,")
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "atlas_glyphs: []Atlas_Glyph = {")

	for ag in atlas_glyphs {
		fmt.fprintf(f, "\t{{ rect = {{%v, %v, %v, %v}}, value = %q, offset_x = %v, offset_y = %v, advance_x = %v}},\n",
			ag.rect.x, ag.rect.y, ag.rect.width, ag.rect.height, ag.glyph.value, ag.glyph.offsetX, ag.glyph.offsetY, ag.glyph.advanceX)
	}

	fmt.fprintln(f, "}\n")

	fmt.fprintf(f, "shapes_texture_rect := Rect {{%v, %v, %v, %v}}\n\n", shapes_texture_rect.x, shapes_texture_rect.y, shapes_texture_rect.width, shapes_texture_rect.height)

	fmt.fprintln(f, "Tile_Id :: enum {")
	for y in 0..<10 {
		for x in 0..<10 {
			fmt.fprintf(f, "\tT0Y%vX%v,\n", y, x)
		}
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "atlas_tiles := #partial [Tile_Id]Rect {")

	for at in atlas_tiles {
		fmt.fprintf(f, "\t.T0Y%vX%v = {{%v, %v, %v, %v}},\n",
			 at.coord.y, at.coord.x, at.rect.x, at.rect.y, at.rect.width, at.rect.height)
	}

	fmt.fprintln(f, "}\n")

	fmt.fprintln(f, "Animation_Name :: enum {")
	fmt.fprint(f, "\tNone,\n")
	for r in animations {
		fmt.fprintf(f, "\t%s,\n", r.name)
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "Atlas_Animation :: struct {")
	fmt.fprintln(f, "\tfirst_frame: TextureName,")
	fmt.fprintln(f, "\tlast_frame: TextureName,")
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "atlas_animations := [Animation_Name]Atlas_Animation {")
	fmt.fprint(f, "\t.None = {},\n")

	for a in animations {
		fmt.fprintf(f, "\t.%v = {{ first_frame = .%v, last_frame = .%v }},\n",
			a.name, a.first_texture, a.last_texture)
	}

	fmt.fprintln(f, "}\n")

	fmt.fprintln(f, "TEXTURE_ATLAS_FILENAME :: \"atlas.png\"")
	fmt.fprintf(f, "ATLAS_FONT_SIZE :: %v\n", FONT_SIZE)
	fmt.fprintf(f, "LETTERS_IN_FONT :: \"%s\"\n", LETTERS_IN_FONT)
}
