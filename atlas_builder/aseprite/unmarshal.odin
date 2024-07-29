package aseprite_file_handler

import "base:runtime"
import "core:io"
import "core:os"
import "core:fmt"
import "core:log"
import "core:bytes"
import "core:bufio"
import "core:strings"
import "core:compress/zlib"
import "core:encoding/endian"

import vzlib "vendor:zlib"


unmarshal_from_bytes_buff :: proc(r: ^bytes.Reader, doc: ^Document, allocator := context.allocator)-> (total_read: int, err: Unmarshal_Error) {
    rr, ok := io.to_reader(bytes.reader_to_stream(r))
    if !ok {
        return total_read, .Unable_Make_Reader
    }
    return unmarshal(rr, doc, allocator)
}

unmarshal_from_bufio :: proc(r: ^bufio.Reader, doc: ^Document, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    rr, ok := io.to_reader(bufio.reader_to_stream(r))
    if !ok {
        return total_read, .Unable_Make_Reader
    }
    return unmarshal(rr, doc, allocator)
}

unmarshal_from_filename :: proc(name: string, doc: ^Document, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    fd, err_no := os.open(name, os.O_RDONLY, 0)
    if err_no != 0 {
        return total_read, .Unable_To_Open_File
    }
    defer os.close(fd)
    return unmarshal(fd, doc, allocator)
}

unmarshal_from_handle :: proc(h: os.Handle, doc: ^Document, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    rr, ok := io.to_reader(os.stream_from_handle(h))
    if !ok {
        return total_read, .Unable_Make_Reader
    }
    return unmarshal(rr, doc, allocator)
}

unmarshal_from_slice :: proc(b: []byte, doc: ^Document, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    r: bytes.Reader
    bytes.reader_init(&r, b[:])
    return unmarshal(&r, doc, allocator)
}

unmarshal :: proc{
    unmarshal_from_bytes_buff, unmarshal_from_slice, unmarshal_from_handle, 
    unmarshal_from_filename, unmarshal_from_bufio, unmarshal_from_reader,
}

unmarshal_from_reader :: proc(r: io.Reader, doc: ^Document, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    ud_map_warn, icc_profile_warn: bool
    rt := &total_read
    set := io.query(r)
    h: File_Header
    h.size = read_dword(r, rt) or_return

    if io.Stream_Mode.Size in set {
        stream_size := io.size(r) or_return
        if stream_size != i64(h.size) {
            return total_read, .Data_Size_Not_Equal_To_Header
        }
    }
    
    magic := read_word(r, rt) or_return
    if magic != FILE_MAGIC_NUM {
        return total_read, .Bad_File_Magic_Number
    } 

    frames := read_word(r, rt) or_return

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

    doc.header = h
    doc.frames = make([]Frame, int(frames), allocator) or_return

    for &frame in doc.frames {
        fh: Frame_Header
        frame_size := read_dword(r, rt) or_return
        frame_magic := read_word(r, rt) or_return
        if frame_magic != FRAME_MAGIC_NUM {
            return total_read, .Bad_Frame_Magic_Number
        }
        fh.old_num_of_chunks = read_word(r, rt) or_return
        fh.duration = read_word(r, rt) or_return
        read_skip(r, 2, rt) or_return
        fh.num_of_chunks = read_dword(r, rt) or_return

        chunks := int(fh.num_of_chunks) 
        if chunks == 0 {
            chunks = int(fh.old_num_of_chunks)
        }

        frame.header = fh
        frame.chunks = make([]Chunk, chunks, allocator) or_return

        for &chunk in frame.chunks {
            c_size := int(read_dword(r, rt) or_return)
            c_type := cast(Chunk_Types)read_word(r, rt) or_return

            switch c_type {
            case .old_palette_256:
                op: Old_Palette_256_Chunk
                op_size := cast(int)read_word(r, rt) or_return
                op = make(Old_Palette_256_Chunk, op_size, allocator) or_return

                for &packet in op {
                    packet.entries_to_skip = read_byte(r, rt) or_return
                    packet.num_colors = read_byte(r, rt) or_return
                    count := int(packet.num_colors)
                    if count == 0 {
                        count = 256
                    }

                    packet.colors = make([]Color_RGB, count, allocator) or_return
                    for &c in packet.colors {
                        c[2] = read_byte(r, rt) or_return
                        c[1] = read_byte(r, rt) or_return
                        c[0] = read_byte(r, rt) or_return
                    }
                }
                chunk = op

            case .old_palette_64:
                op: Old_Palette_64_Chunk
                op_size := cast(int)read_word(r, rt) or_return
                op = make(Old_Palette_64_Chunk, op_size, allocator) or_return

                for &packet in op {
                    packet.entries_to_skip = read_byte(r, rt) or_return
                    packet.num_colors = read_byte(r, rt) or_return
                    count := int(packet.num_colors)
                    if count == 0 {
                        count = 256
                    }

                    packet.colors = make([]Color_RGB, count, allocator) or_return
                    for &c in packet.colors {
                        c[2] = read_byte(r, rt) or_return
                        c[1] = read_byte(r, rt) or_return
                        c[0] = read_byte(r, rt) or_return
                    }
                }
                chunk = op

            case .layer:
                l: Layer_Chunk
                l.flags = transmute(Layer_Chunk_Flags)read_word(r, rt) or_return
                l.type = Layer_Types(read_word(r, rt) or_return)
                l.child_level = read_word(r, rt) or_return
                l.default_width = read_word(r, rt) or_return
                l.default_height = read_word(r, rt) or_return
                l.blend_mode = Layer_Blend_Mode(read_word(r, rt) or_return)
                l.opacity = read_byte(r, rt) or_return
                read_skip(r, 3, rt) or_return
                l.name = read_string(r, rt, allocator) or_return

                if l.type == .Tilemap {
                    l.tileset_index = read_dword(r, rt) or_return
                }
                chunk = l

            case .cel:
                c: Cel_Chunk
                c.layer_index = read_word(r, rt) or_return
                c.x = read_short(r, rt) or_return
                c.y = read_short(r, rt) or_return
                c.opacity_level = read_byte(r, rt) or_return
                c.type = Cel_Types(read_word(r, rt) or_return)
                c.z_index = read_short(r, rt) or_return
                read_skip(r, 5, rt) or_return

                switch c.type {
                case .Raw:
                    cel: Raw_Cel
                    cel.width = read_word(r, rt) or_return
                    cel.height = read_word(r, rt) or_return
                    cel.pixel = make([]PIXEL, int(cel.width * cel.height), allocator) or_return
                    read_bytes(r, cel.pixel[:], rt) or_return
                    c.cel = cel

                case .Linked_Cel:
                    c.cel = Linked_Cel(read_word(r, rt) or_return)

                case .Compressed_Image:
                    cel: Com_Image_Cel
                    cel.width = read_word(r, rt) or_return
                    cel.height = read_word(r, rt) or_return

                    com_size := c_size-26
                    if com_size <= 0 {
                        return total_read, .Invalid_Compression_Size
                    }

                    buf: bytes.Buffer
                    defer bytes.buffer_destroy(&buf)
                    data := make([]byte, com_size, allocator) or_return

                    defer delete(data)
                    read_bytes(r, data[:], rt) or_return

                    exp_size := int(WORD(h.color_depth) / 8 * cel.height * cel.width)
                    zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

                    cel.pixel = make([]byte, exp_size, allocator) or_return
                    copy(cel.pixel[:], buf.buf[:])

                    c.cel = cel

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
                        return total_read, .Invalid_Compression_Size
                    }

                    data := make([]byte, com_size, allocator) or_return
                    defer delete(data)
                    read_bytes(r, data[:], rt) or_return
                    exp_size := int(WORD(h.color_depth) / 8 * cel.height * cel.width)
                    zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

                    br: bytes.Reader
                    bytes.reader_init(&br, buf.buf[:])
                    rr, ok := io.to_reader(bytes.reader_to_stream(&br))
                    if !ok { return total_read, .Unable_Make_Reader }

                    // FIXME: Is leaking. Not writing data?
                    cel.tiles = make([]TILE, cel.height * cel.width, allocator) or_return
                    read_tiles(rr, cel.tiles[:], cel.bitmask_id, rt) or_return

                    c.cel = cel

                case:
                    return total_read, .Invalid_Cel_Type
                }
                chunk = c

            case .cel_extra:
                ce: Cel_Extra_Chunk
                ce.flags = transmute(Cel_Extra_Flags)read_word(r, rt) or_return
                ce.x = read_fixed(r, rt) or_return
                ce.y = read_fixed(r, rt) or_return
                ce.width = read_fixed(r, rt) or_return
                ce.height = read_fixed(r, rt) or_return
                chunk = ce

            case .color_profile:
                cp: Color_Profile_Chunk
                cp.type = Color_Profile_Type(read_word(r, rt) or_return)
                cp.flags = transmute(Color_Profile_Flags)read_word(r, rt) or_return
                cp.fixed_gamma = read_fixed(r, rt) or_return
                read_skip(r, 8, rt) or_return

                if cp.type == .ICC {
                    icc_size := cast(int)read_dword(r, rt) or_return
                    cp.icc = make(ICC_Profile, icc_size, allocator) or_return
                    read_bytes(r, cast([]u8)cp.icc.(ICC_Profile)[:], rt) or_return
                    if !icc_profile_warn {
                        log.warn("Embedded ICC Color Profiles are currently not supported.")
                        icc_profile_warn = true
                    }
                }
                chunk = cp

            case .external_files:
                ef: External_Files_Chunk
                entries := read_dword(r, rt) or_return
                ef = make([]External_Files_Entry, entries, allocator) or_return
                read_skip(r, 8, rt) or_return

                for &entry in ef {
                    entry.id = read_dword(r, rt) or_return
                    entry.type = ExF_Entry_Type(read_byte(r, rt) or_return)
                    read_skip(r, 7, rt) or_return
                    entry.file_name_or_id = read_string(r, rt, allocator) or_return
                }
                chunk = ef

            case .mask:
                m: Mask_Chunk
                m.x = read_short(r, rt) or_return
                m.y = read_short(r, rt) or_return
                m.width = read_word(r, rt) or_return
                m.height = read_word(r, rt) or_return
                read_skip(r, 8, rt) or_return
                m.name = read_string(r, rt, allocator) or_return

                size := int(m.height * ((m.width + 7) / 8))
                m.bit_map_data = make([]BYTE, size, allocator) or_return
                read_bytes(r, m.bit_map_data[:], rt) or_return

                chunk = m

            case .path:
                chunk = Path_Chunk{}

            case .tags:
                tc: Tags_Chunk
                size := cast(int)read_word(r, rt) or_return
                tc = make([]Tag, size, allocator) or_return
                read_skip(r, 8, rt) or_return

                for &tag in tc {
                    tag.from_frame = read_word(r, rt) or_return
                    tag.to_frame = read_word(r, rt) or_return
                    tag.loop_direction = Tag_Loop_Dir(read_byte(r, rt) or_return)
                    tag.repeat = read_word(r, rt) or_return
                    read_skip(r, 6, rt) or_return
                    tag.tag_color[2] = read_byte(r, rt) or_return
                    tag.tag_color[1] = read_byte(r, rt) or_return
                    tag.tag_color[0] = read_byte(r, rt) or_return
                    read_byte(r, rt) or_return
                    tag.name = read_string(r, rt, allocator) or_return
                }
                chunk = tc

            case .palette:
                pal: Palette_Chunk
                pal.size = read_dword(r, rt) or_return
                pal.first_index = read_dword(r, rt) or_return
                pal.last_index = read_dword(r, rt) or_return
                size := int(pal.last_index - pal.first_index + 1)
                pal.entries = make([]Palette_Entry, size, allocator) or_return
                read_skip(r, 8, rt) or_return

                for &entry in pal.entries {
                    pf := transmute(Pal_Flags)read_word(r, rt) or_return
                    entry.color[3] = read_byte(r, rt) or_return
                    entry.color[2] = read_byte(r, rt) or_return
                    entry.color[1] = read_byte(r, rt) or_return
                    entry.color[0] = read_byte(r, rt) or_return

                    if .Has_Name in pf {
                        entry.name = read_string(r, rt, allocator) or_return
                    }
                }

                chunk = pal

            case .user_data:
                // FIXME: This isn't working. Very annoying.
                ud: User_Data_Chunk
                flags := transmute(UD_Flags)read_dword(r, rt) or_return

                if .Text in flags {
                    ud.text = read_string(r, rt, allocator) or_return
                }
                if .Color in flags {
                    colour: Color_RGBA
                    colour[3] = read_byte(r, rt) or_return
                    colour[2] = read_byte(r, rt) or_return
                    colour[1] = read_byte(r, rt) or_return
                    colour[0] = read_byte(r, rt) or_return
                    ud.color = colour
                }
                if .Properties in flags {
                    if !ud_map_warn {
                        log.warn("Only Reading User Data Maps is supported rn.")
                        ud_map_warn = true
                    }

                    total_size := read_dword(r, rt) or_return
                    map_num := read_dword(r, rt) or_return
                    // FIXME: Is leaking. Not writing data?
                    maps := make(Properties_Map, map_num, allocator) or_return
                    for i in 0..<int(map_num) {
                        key := read_dword(r, rt) or_return
                        //maps[key] = read_ud_value(r, .Properties, rt, allocator) or_return

                        prop_num := int(read_dword(r, rt) or_return)
                        val := make(Properties, prop_num, allocator) or_return

                        for n in 0..<prop_num {
                            name := read_string(r, rt, allocator) or_return
                            defer delete(name)
                            type := Property_Type(read_word(r, rt) or_return)
                            val[name] = read_ud_value(r, type, rt, allocator) or_return
                        }

                        maps[key] = val
                    }
                    ud.maps = maps
                }

                chunk = ud

            case .slice:
                s: Slice_Chunk
                keys := int(read_dword(r, rt) or_return)
                s.flags = transmute(Slice_Flags)read_dword(r, rt) or_return
                read_dword(r, rt) or_return
                s.name = read_string(r, rt, allocator) or_return
                s.keys = make([]Slice_Key, keys, allocator) or_return

                for &key in s.keys {
                    key.frame_num = read_dword(r, rt) or_return
                    key.x = read_long(r, rt) or_return
                    key.y = read_long(r, rt) or_return
                    key.width = read_dword(r, rt) or_return
                    key.height = read_dword(r, rt) or_return

                    if .Patched_slice in s.flags {
                        cen: Slice_Center
                        cen.x = read_long(r, rt) or_return
                        cen.y = read_long(r, rt) or_return
                        cen.width = read_dword(r, rt) or_return
                        cen.height = read_dword(r, rt) or_return
                        key.center = cen
                    }

                    if .Pivot_Information in s.flags {
                        p: Slice_Pivot
                        p.x = read_long(r, rt) or_return
                        p.y = read_long(r, rt) or_return
                        key.pivot = p
                    }
                }

                chunk = s

            case .tileset:
                ts: Tileset_Chunk
                ts.id = read_dword(r, rt) or_return
                ts.flags = transmute(Tileset_Flags)read_dword(r, rt) or_return
                ts.num_of_tiles = read_dword(r, rt) or_return
                ts.width = read_word(r, rt) or_return
                ts.height = read_word(r, rt) or_return
                ts.base_index = read_short(r, rt) or_return
                read_skip(r, 14, rt)
                ts.name = read_string(r, rt, allocator) or_return

                if .Include_Link_To_External_File in ts.flags {
                    ex: Tileset_External
                    ex.file_id = read_dword(r, rt) or_return
                    ex.tileset_id = read_dword(r, rt) or_return
                    ts.external = ex
                }
                if .Include_Tiles_Inside_This_File in ts.flags {
                    tc: Tileset_Compressed
                    size := int(read_dword(r, rt) or_return)

                    buf: bytes.Buffer
                    defer bytes.buffer_destroy(&buf)

                    data := make([]byte, size, allocator) or_return
                    defer delete(data)
                    read_bytes(r, data[:], rt) or_return

                    exp_size := int(ts.width) * int(ts.height) * int(ts.num_of_tiles)
                    zlib.inflate(data[:], &buf, expected_output_size=exp_size) or_return

                    tc = make(Tileset_Compressed, exp_size, allocator) or_return
                    copy(tc[:], cast(Tileset_Compressed)buf.buf[:])
                    ts.compressed = tc

                }
                chunk = ts

            case .none:
                fallthrough
            case:
                log.error("Invalid Chunk Type", chunk)
                return total_read, .Invalid_Chunk_Type
            }
        }
    }
    return
}
