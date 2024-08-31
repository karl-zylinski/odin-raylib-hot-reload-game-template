package aseprite_file_handler

import "base:intrinsics"
import "core:io"
import "core:fmt"
import "core:log"
import "core:bytes"
import "core:compress/zlib"
_::fmt
_::log

read_file_header :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (h: File_Header, err: Unmarshal_Error) {
    h.size = read_dword(r, rt) or_return

    if io.Stream_Mode.Size in io.query(r) {
        stream_size := io.size(r) or_return
        if stream_size != i64(h.size) {
            return {}, .Data_Size_Not_Equal_To_Header
        }
    }
    
    magic := read_word(r, rt) or_return
    if magic != FILE_MAGIC_NUM {
        return {}, .Bad_File_Magic_Number
    } 

    h.frames = read_word(r, rt) or_return

    h.width = read_word(r, rt) or_return
    h.height = read_word(r, rt) or_return
    h.color_depth = Color_Depth(read_word(r, rt) or_return)

    h.flags = transmute(File_Flags)read_dword(r, rt) or_return
    h.speed = read_word(r, rt) or_return
    read_skip(r, 4+4, rt) or_return

    h.transparent_index = read_byte(r, rt) or_return
    read_skip(r, 3, rt) or_return

    h.num_of_colors = read_word(r, rt) or_return
    h.ratio_width = read_byte(r, rt) or_return
    h.ratio_height = read_byte(r, rt) or_return

    h.x = read_short(r, rt) or_return
    h.y = read_short(r, rt) or_return

    h.grid_width = read_word(r, rt) or_return
    h.grid_height = read_word(r, rt) or_return
    read_skip(r, 84, rt) or_return

    return
}


read_old_palette_256 :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Old_Palette_256_Chunk, err: Unmarshal_Error) {
    op_size := cast(int)read_word(r, rt) or_return
    chunk = make(Old_Palette_256_Chunk, op_size, allocator) or_return

    for &packet in chunk {
        packet.entries_to_skip = read_byte(r, rt) or_return
        packet.num_colors = read_byte(r, rt) or_return
        count := int(packet.num_colors)
        if count == 0 {
            count = 256
        }

        packet.colors = make([]Color_RGB, count, allocator) or_return
        for &c in packet.colors {
            // TODO: Maybe read into an array???
            c[0] = read_byte(r, rt) or_return
            c[1] = read_byte(r, rt) or_return
            c[2] = read_byte(r, rt) or_return
        }
    }
    return
}

read_old_palette_64 :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Old_Palette_64_Chunk, err: Unmarshal_Error) {
    op_size := cast(int)read_word(r, rt) or_return
    chunk = make(Old_Palette_64_Chunk, op_size, allocator) or_return

    for &packet in chunk {
        packet.entries_to_skip = read_byte(r, rt) or_return
        packet.num_colors = read_byte(r, rt) or_return
        count := int(packet.num_colors)
        if count == 0 {
            count = 256
        }

        packet.colors = make([]Color_RGB, count, allocator) or_return
        for &c in packet.colors {
            // TODO: Maybe read into an array???
            c[0] = read_byte(r, rt) or_return
            c[1] = read_byte(r, rt) or_return
            c[2] = read_byte(r, rt) or_return
        }
    }
    return
}

read_layer :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Layer_Chunk, err: Unmarshal_Error) {
    chunk.flags = transmute(Layer_Chunk_Flags)read_word(r, rt) or_return
    chunk.type = Layer_Types(read_word(r, rt) or_return)
    chunk.child_level = read_word(r, rt) or_return
    chunk.default_width = read_word(r, rt) or_return
    chunk.default_height = read_word(r, rt) or_return
    chunk.blend_mode = Layer_Blend_Mode(read_word(r, rt) or_return)
    chunk.opacity = read_byte(r, rt) or_return
    read_skip(r, 3, rt) or_return
    chunk.name = read_string(r, rt, allocator) or_return

    if chunk.type == .Tilemap {
        chunk.tileset_index = read_dword(r, rt) or_return
    }
    return
}

read_cel :: proc(r: io.Reader, rt: ^int, color_depth: int, c_size: int, allocator := context.allocator) -> (chunk: Cel_Chunk, err: Unmarshal_Error) {
    context.allocator = allocator
    chunk.layer_index = read_word(r, rt) or_return
    chunk.x = read_short(r, rt) or_return
    chunk.y = read_short(r, rt) or_return
    chunk.opacity_level = read_byte(r, rt) or_return
    chunk.type = Cel_Types(read_word(r, rt) or_return)
    chunk.z_index = read_short(r, rt) or_return
    read_skip(r, 5, rt) or_return

    switch chunk.type {
    case .Raw:
        cel: Raw_Cel
        cel.width = read_word(r, rt) or_return
        cel.height = read_word(r, rt) or_return
        cel.pixel = make([]PIXEL, int(cel.width * cel.height)) or_return
        read_bytes(r, cel.pixel[:], rt) or_return
        chunk.cel = cel

    case .Linked_Cel:
        chunk.cel = Linked_Cel(read_word(r, rt) or_return)

    case .Compressed_Image:
        cel: Com_Image_Cel
        cel.width = read_word(r, rt) or_return
        cel.height = read_word(r, rt) or_return

        com_size := c_size-26
        if com_size <= 0 {
            err = .Invalid_Compression_Size
            return
        }

        buf: bytes.Buffer
        defer bytes.buffer_destroy(&buf)
        data := make([]byte, com_size) or_return

        defer delete(data)
        read_bytes(r, data[:], rt) or_return

        exp_size := color_depth / 8 * int(cel.height) * int(cel.width)
        zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

        cel.pixel = make([]byte, exp_size) or_return
        copy(cel.pixel[:], buf.buf[:])

        chunk.cel = cel

    case .Compressed_Tilemap:
        cel: Com_Tilemap_Cel
        cel.width = read_word(r, rt) or_return
        cel.height = read_word(r, rt) or_return
        cel.bits_per_tile = read_word(r, rt) or_return
        cel.bitmask_id = Tile_ID(read_dword(r, rt) or_return)
        cel.bitmask_x = read_dword(r, rt) or_return
        cel.bitmask_y = read_dword(r, rt) or_return
        cel.bitmask_diagonal = read_dword(r, rt) or_return
        read_skip(r, 10, rt) or_return

        buf: bytes.Buffer
        defer bytes.buffer_destroy(&buf)
        // size_of(DWORD*5, WORD*6, SHORT*3, BYTE, SKIPED*15)-1
        com_size := c_size-54
        if com_size <= 0 {
            err = .Invalid_Compression_Size
            return
        }

        data := make([]byte, com_size) or_return
        defer delete(data)
        read_bytes(r, data[:], rt) or_return
        exp_size := color_depth / 8 * int(cel.height) * int(cel.width)
        zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

        br: bytes.Reader
        bytes.reader_init(&br, buf.buf[:])
        rr, ok := io.to_reader(bytes.reader_to_stream(&br))
        if !ok { err = .Unable_Make_Reader; return }

        cel.tiles = make([]TILE, cel.height * cel.width) or_return
        read_tiles(rr, cel.tiles[:], cel.bitmask_id, rt) or_return

        chunk.cel = cel

    case:
        err = .Invalid_Cel_Type
        return
    }
    return
}

read_cel_extra :: proc(r: io.Reader, rt: ^int) -> (chunk: Cel_Extra_Chunk, err: Unmarshal_Error) {
    chunk.flags = transmute(Cel_Extra_Flags)read_word(r, rt) or_return
    chunk.x = read_fixed(r, rt) or_return
    chunk.y = read_fixed(r, rt) or_return
    chunk.width = read_fixed(r, rt) or_return
    chunk.height = read_fixed(r, rt) or_return
    return
}

read_color_profile :: proc(r: io.Reader, rt: ^int, warned: ^bool, allocator := context.allocator) -> (chunk: Color_Profile_Chunk, err: Unmarshal_Error) {
    chunk.type = Color_Profile_Type(read_word(r, rt) or_return)
    chunk.flags = transmute(Color_Profile_Flags)read_word(r, rt) or_return
    chunk.fixed_gamma = read_fixed(r, rt) or_return
    read_skip(r, 8, rt) or_return

    if chunk.type == .ICC {
        icc_size := cast(int)read_dword(r, rt) or_return
        chunk.icc = make(ICC_Profile, icc_size, allocator) or_return
        read_bytes(r, cast([]u8)chunk.icc.(ICC_Profile)[:], rt) or_return
        if !warned^ {
            log.warn("Embedded ICC Color Profiles are currently not supported.")
            warned^ = true
        }
    }
    return
}

read_external_files :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: External_Files_Chunk, err: Unmarshal_Error) {
    entries := read_dword(r, rt) or_return
    chunk = make([]External_Files_Entry, entries, allocator) or_return
    read_skip(r, 8, rt) or_return

    for &entry in chunk {
        entry.id = read_dword(r, rt) or_return
        entry.type = ExF_Entry_Type(read_byte(r, rt) or_return)
        read_skip(r, 7, rt) or_return
        entry.file_name_or_id = read_string(r, rt, allocator) or_return
    }
    return
}

read_mask :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Mask_Chunk, err: Unmarshal_Error) {
    chunk.x = read_short(r, rt) or_return
    chunk.y = read_short(r, rt) or_return
    chunk.width = read_word(r, rt) or_return
    chunk.height = read_word(r, rt) or_return
    read_skip(r, 8, rt) or_return
    chunk.name = read_string(r, rt, allocator) or_return

    size := int(chunk.height) * ((int(chunk.width) + 7) / 8)
    chunk.bit_map_data = make([]BYTE, size, allocator) or_return
    read_bytes(r, chunk.bit_map_data[:], rt) or_return
    return
}

read_path :: proc() -> (chunk: Path_Chunk) {
    return
}

read_tags :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Tags_Chunk, err: Unmarshal_Error) {
    size := cast(int)read_word(r, rt) or_return
    chunk = make([]Tag, size, allocator) or_return
    read_skip(r, 8, rt) or_return

    for &tag in chunk {
        tag.from_frame = read_word(r, rt) or_return
        tag.to_frame = read_word(r, rt) or_return
        tag.loop_direction = Tag_Loop_Dir(read_byte(r, rt) or_return)
        tag.repeat = read_word(r, rt) or_return
        read_skip(r, 6, rt) or_return
        // TODO: Maybe read into an array???
        tag.tag_color[0] = read_byte(r, rt) or_return
        tag.tag_color[1] = read_byte(r, rt) or_return
        tag.tag_color[2] = read_byte(r, rt) or_return
        read_byte(r, rt) or_return
        tag.name = read_string(r, rt, allocator) or_return
    }
    return
}

read_palette :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Palette_Chunk, err: Unmarshal_Error) {
    chunk.size = read_dword(r, rt) or_return
    chunk.first_index = read_dword(r, rt) or_return
    chunk.last_index = read_dword(r, rt) or_return
    size := int(chunk.last_index - chunk.first_index + 1)
    chunk.entries = make([]Palette_Entry, size, allocator) or_return
    read_skip(r, 8, rt) or_return

    for &entry in chunk.entries {
        // TODO: Maybe read into an array???
        pf := transmute(Pal_Flags)read_word(r, rt) or_return
        entry.color[0] = read_byte(r, rt) or_return
        entry.color[1] = read_byte(r, rt) or_return
        entry.color[2] = read_byte(r, rt) or_return
        entry.color[3] = read_byte(r, rt) or_return

        if .Has_Name in pf {
            entry.name = read_string(r, rt, allocator) or_return
        }
    }
    return
}

read_user_data :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: User_Data_Chunk, err: Unmarshal_Error) {
    flags := transmute(UD_Flags)read_dword(r, rt) or_return

    if .Text in flags {
        chunk.text = read_string(r, rt) or_return
    }
    if .Color in flags {
        // TODO: Maybe read into an array???
        colour: Color_RGBA
        colour[0] = read_byte(r, rt) or_return
        colour[1] = read_byte(r, rt) or_return
        colour[2] = read_byte(r, rt) or_return
        colour[3] = read_byte(r, rt) or_return 
        chunk.color = colour
    }
    if .Properties in flags {
        //map_size := read_dword(r, rt) or_return
        read_skip(r, 4, rt) or_return
        map_num := read_dword(r, rt) or_return
        maps := make(Properties_Map, map_num) or_return
        for _ in 0..<int(map_num) {
            key := read_dword(r, rt) or_return

            prop_num := int(read_dword(r, rt) or_return)
            val := make(Properties, prop_num) or_return

            for _ in 0..<prop_num {
                name := read_string(r, rt) or_return
                defer delete(name)
                type := Property_Type(read_word(r, rt) or_return)
                val[name] = read_ud_value(r, type, rt) or_return
            }

            maps[key] = val
        }
        chunk.maps = maps
    }
    return
}

read_slice :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Slice_Chunk, err: Unmarshal_Error) {
    keys := int(read_dword(r, rt) or_return)
    chunk.flags = transmute(Slice_Flags)read_dword(r, rt) or_return
    read_dword(r, rt) or_return
    chunk.name = read_string(r, rt) or_return
    chunk.keys = make([]Slice_Key, keys, allocator) or_return

    for &key in chunk.keys {
        key.frame_num = read_dword(r, rt) or_return
        key.x = read_long(r, rt) or_return
        key.y = read_long(r, rt) or_return
        key.width = read_dword(r, rt) or_return
        key.height = read_dword(r, rt) or_return

        if .Patched_slice in chunk.flags {
            cen: Slice_Center
            cen.x = read_long(r, rt) or_return
            cen.y = read_long(r, rt) or_return
            cen.width = read_dword(r, rt) or_return
            cen.height = read_dword(r, rt) or_return
            key.center = cen
        }

        if .Pivot_Information in chunk.flags {
            p: Slice_Pivot
            p.x = read_long(r, rt) or_return
            p.y = read_long(r, rt) or_return
            key.pivot = p
        }
    }
    return
}

read_tileset :: proc(r: io.Reader, rt: ^int, allocator := context.allocator) -> (chunk: Tileset_Chunk, err: Unmarshal_Error) {
    chunk.id = read_dword(r, rt) or_return
    flags := transmute(Tileset_Flags)read_dword(r, rt) or_return
    chunk.num_of_tiles = read_dword(r, rt) or_return
    chunk.width = read_word(r, rt) or_return
    chunk.height = read_word(r, rt) or_return
    chunk.base_index = read_short(r, rt) or_return
    read_skip(r, 14, rt)
    chunk.name = read_string(r, rt) or_return

    if .Include_Link_To_External_File in flags {
        ex: Tileset_External
        ex.file_id = read_dword(r, rt) or_return
        ex.tileset_id = read_dword(r, rt) or_return
        chunk.external = ex
    }
    if .Include_Tiles_Inside_This_File in flags {
        tc: Tileset_Compressed
        size := int(read_dword(r, rt) or_return)

        buf: bytes.Buffer
        defer bytes.buffer_destroy(&buf)

        data := make([]byte, size, allocator) or_return
        defer delete(data)
        read_bytes(r, data[:], rt) or_return

        exp_size := int(chunk.width) * int(chunk.height) * int(chunk.num_of_tiles)
        zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

        tc = make(Tileset_Compressed, exp_size, allocator) or_return
        copy(tc[:], cast(Tileset_Compressed)buf.buf[:])
        chunk.compressed = tc

    }
    return
}
