package aseprite_file_handler

import "base:runtime"
import "core:io"
import "core:os"
import "core:fmt"
import "core:log"
import "core:bytes"
import "core:slice"
import "core:bufio"
import "core:strings"
import "core:encoding/endian"
import "vendor:zlib"


marshal_to_bytes_buff :: proc(b: ^bytes.Buffer, doc: ^Document, allocator := context.allocator)-> (file_size: int, err: Marshal_Error) {
    w, ok := io.to_writer(bytes.buffer_to_stream(b))
    if !ok {
        return file_size, .Unable_Make_Writer
    }
    return marshal(w, doc, allocator)
}

marshal_to_handle :: proc(h: os.Handle, doc: ^Document, allocator := context.allocator)-> (file_size: int, err: Marshal_Error) {
    w, ok := io.to_writer(os.stream_from_handle(h))
    if !ok {
        return file_size, .Unable_Make_Writer
    }
    return marshal(w, doc, allocator)
}

marshal_to_slice :: proc(b: []byte, doc: ^Document, allocator := context.allocator)-> (file_size: int, err: Marshal_Error) {
    buf: bytes.Buffer
    defer bytes.buffer_destroy(&buf)
    file_size, err = marshal(&buf, doc, allocator)
    if err != nil {
        return
    }
    if len(b) < len(buf.buf[buf.off:]) {
        return file_size, Marshal_Errors.Buffer_Not_Big_Enough
    }
    copy_slice(b[:], buf.buf[buf.off:])
    return
}

marshal_to_dynamic :: proc(b: ^[dynamic]byte, doc: ^Document, allocator := context.allocator)-> (file_size: int, err: Marshal_Error) {
    buf: bytes.Buffer
    defer bytes.buffer_destroy(&buf)
    marshal(&buf, doc, allocator) or_return
    append(b, ..buf.buf[:])
    return
}

marshal_to_bufio :: proc(w: ^bufio.Writer, doc: ^Document, allocator := context.allocator) -> (file_size: int, err: Marshal_Error) {
    ww, ok := io.to_writer(bufio.writer_to_stream(w))
    if !ok {
        return file_size, .Unable_Make_Writer
    }
    return marshal(ww, doc, allocator)
}

marshal :: proc{
    marshal_to_bytes_buff, marshal_to_slice, marshal_to_handle, 
    marshal_to_dynamic, marshal_to_bufio, marshal_to_writer,
}

marshal_to_writer :: proc(ww: io.Writer, doc: ^Document, allocator := context.allocator) -> (file_size: int, err: Marshal_Error) {
    ud_map_warn: bool
    s := &file_size
    b: bytes.Buffer
    defer bytes.buffer_destroy(&b)

    w, ok := io.to_writer(bytes.buffer_to_stream(&b))
    if !ok {
        return file_size, .Unable_Make_Writer
    }

    write(w, FILE_MAGIC_NUM, s) or_return
    write(w, WORD(len(doc.frames)), s) or_return
    write(w, doc.header.width, s) or_return
    write(w, doc.header.height, s) or_return
    write(w, WORD(doc.header.color_depth), s) or_return
    write(w, transmute(DWORD)doc.header.flags, s) or_return
    write(w, doc.header.speed, s) or_return
    write_skip(w, 8, s) or_return
    write(w, doc.header.transparent_index, s) or_return
    write_skip(w, 3, s) or_return
    write(w, doc.header.num_of_colors, s) or_return
    write(w, doc.header.ratio_width, s) or_return
    write(w, doc.header.ratio_height, s) or_return
    write(w, doc.header.x, s) or_return
    write(w, doc.header.y, s) or_return
    write(w, doc.header.grid_width, s) or_return
    write(w, doc.header.grid_height, s) or_return
    write_skip(w, 84, s) or_return

    for frame in doc.frames {
        fb: bytes.Buffer
        defer bytes.buffer_destroy(&fb)
        fw, ok2 := io.to_writer(bytes.buffer_to_stream(&fb))
        if !ok2 {
            return file_size, .Unable_Make_Writer
        }
        frame_size: int
        fs := &frame_size
        
        write(fw, FRAME_MAGIC_NUM, fs) or_return
        write(fw, frame.header.old_num_of_chunks, fs) or_return
        write(fw, frame.header.duration, fs) or_return
        write_skip(fw, 2, fs) or_return
        write(fw, frame.header.num_of_chunks, fs) or_return

        for chunk in frame.chunks {
            cb: bytes.Buffer
            defer bytes.buffer_destroy(&cb)
            cw, ok3 := io.to_writer(bytes.buffer_to_stream(&cb))
            if !ok3 {
                return file_size, .Unable_Make_Writer
            }
            chunk_size: int
            cs := &chunk_size

            chunk_type := get_chunk_type(chunk) or_return
            write(cw, chunk_type, cs) or_return

            switch val in chunk {
            case Old_Palette_256_Chunk:
                write(cw, WORD(len(val)), cs) or_return
                for p in val {
                    write(cw, p.entries_to_skip, cs) or_return
                    if len(p.colors) > 256 {
                        return file_size, .Invalid_Old_Palette
                    } else if len(p.colors) == 256 {
                        write_byte(cw, 0, cs) or_return
                    } else {
                        write(cw, p.num_colors, cs) or_return
                    }
                    for c in p.colors {
                        write(cw, c[2], cs) or_return
                        write(cw, c[1], cs) or_return
                        write(cw, c[0], cs) or_return
                    }
                }

            case Old_Palette_64_Chunk:
                write(cw, WORD(len(val)), cs) or_return
                for p in val {
                    write(cw, p.entries_to_skip, cs) or_return
                    if len(p.colors) > 256 {
                        return file_size, .Invalid_Old_Palette
                    } else if len(p.colors) == 256 {
                        write_byte(cw, 0, cs) or_return
                    } else {
                        write(cw, p.num_colors, cs) or_return
                    }
                    for c in p.colors {
                        write(cw, c[2], cs) or_return
                        write(cw, c[1], cs) or_return
                        write(cw, c[0], cs) or_return
                    }
                }
            case Layer_Chunk:
                write(cw, transmute(WORD)val.flags, cs) or_return
                write(cw, WORD(val.type), cs) or_return
                write(cw, val.child_level, cs) or_return
                write(cw, val.default_width, cs) or_return
                write(cw, val.default_height, cs) or_return
                write(cw, WORD(val.blend_mode), cs) or_return
                write(cw, val.opacity, cs) or_return
                write_skip(cw, 3, cs) or_return
                write(cw, val.name, cs) or_return
                if val.type == .Tilemap {
                    write(cw, val.tileset_index, cs) or_return
                }

            case Cel_Chunk:
                write(cw, val.layer_index, cs) or_return
                write(cw, val.x, cs) or_return
                write(cw, val.y, cs) or_return
                write(cw, val.opacity_level, cs) or_return
                cel_type := get_cel_type(val.cel) or_return
                write(cw, cel_type, cs) or_return
                write(cw, val.z_index, cs) or_return
                write_skip(cw, 5, cs) or_return

                switch cel in val.cel {
                case Raw_Cel:
                    write(cw, cel.width, cs) or_return
                    write(cw, cel.height, cs) or_return
                    write(cw, cel.pixel[:], cs) or_return

                case Linked_Cel:
                    write(cw, WORD(cel), cs) or_return

                case Com_Image_Cel:
                    write(cw, cel.width, cs) or_return
                    write(cw, cel.height, cs) or_return

                    com_buf := make([]byte, len(cel.pixel)+64, allocator) or_return
                    defer delete(com_buf)
                    data_rd: [^]u8 = raw_data(cel.pixel[:])
                    com_buf_rd: [^]u8 = raw_data(com_buf[:])

                    config := zlib.z_stream {
                        avail_in=zlib.uInt(len(cel.pixel)), 
                        next_in=&data_rd[0],
                        avail_out=zlib.uInt(len(com_buf)),
                        next_out=&com_buf_rd[0],
                    }
                    
                    en := zlib.deflateInit(&config, zlib.DEFAULT_COMPRESSION)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflate(&config, zlib.FINISH)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflateEnd(&config)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    
                    write(cw, com_buf[:int(config.total_out)], cs) or_return

                case Com_Tilemap_Cel:
                    write(cw, cel.width, cs) or_return
                    write(cw, cel.height, cs) or_return
                    write(cw, cel.bits_per_tile, cs) or_return
                    write(cw, DWORD(cel.bitmask_id), cs) or_return
                    write(cw, cel.bitmask_x, cs) or_return
                    write(cw, cel.bitmask_y, cs) or_return
                    write(cw, cel.bitmask_diagonal, cs) or_return
                    write_skip(cw, 10, cs) or_return


                    buf := make([]u8, len(cel.tiles)*4, allocator) or_return
                    defer delete(buf)
                    n := tiles_to_u8(cel.tiles[:], buf[:]) or_return

                    com_buf := make([]byte, n+64, allocator) or_return
                    defer delete(com_buf)
                    data_rd: [^]u8 = raw_data(buf[:n])
                    com_buf_rd: [^]u8 = raw_data(com_buf[:])

                    config := zlib.z_stream {
                        avail_in=zlib.uInt(n), 
                        next_in=&data_rd[0],
                        avail_out=zlib.uInt(len(com_buf)),
                        next_out=&com_buf_rd[0],
                    }
                    
                    en := zlib.deflateInit(&config, zlib.DEFAULT_COMPRESSION)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflate(&config, zlib.FINISH)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflateEnd(&config)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }

                    write(cw, com_buf[:int(config.total_out)], cs) or_return

                case:
                    return file_size, .Invalid_Cel_Type
                }

            case Cel_Extra_Chunk:
                write(cw, transmute(WORD)val.flags, cs) or_return
                write(cw, val.x, cs) or_return
                write(cw, val.y, cs) or_return
                write(cw, val.width, cs) or_return
                write(cw, val.width, cs) or_return
                write_skip(cw, 16, cs) or_return

            case Color_Profile_Chunk:
                if val.icc != nil {
                    write(cw, WORD(Color_Profile_Type.ICC), cs) or_return
                } else {
                    write(cw, WORD(val.type), cs) or_return
                }
                write(cw, transmute(WORD)val.flags, cs) or_return
                write(cw, val.fixed_gamma, cs) or_return
                write_skip(cw, 8, cs) or_return

                #partial switch v in val.icc {
                case ICC_Profile:
                    write(cw, DWORD(len(v)), cs) or_return
                    write(cw, cast([]u8)v[:], cs) or_return
                }

            case External_Files_Chunk:
                write(cw, DWORD(len(val)), cs) or_return
                write_skip(cw, 8, cs) or_return

                for file in val {
                    write(cw, file.id, cs) or_return
                    write(cw, BYTE(file.type), cs) or_return
                    write_skip(cw, 7, cs) or_return
                    write(cw, file.file_name_or_id, cs) or_return
                }

            case Mask_Chunk:
                write(cw, val.x, cs) or_return
                write(cw, val.y, cs) or_return
                write(cw, val.width, cs) or_return
                write(cw, val.height, cs) or_return
                write_skip(cw, 8, cs) or_return
                write(cw, val.name, cs) or_return 
                write(cw, val.bit_map_data[:], cs) or_return

            case Path_Chunk:

            case Tags_Chunk:
                write(cw, WORD(len(val)), cs) or_return
                write_skip(cw, 8, cs) or_return

                for tag in val {
                    write(cw, tag.from_frame, cs) or_return
                    write(cw, tag.to_frame, cs) or_return
                    write(cw, BYTE(tag.loop_direction), cs) or_return
                    write(cw, tag.repeat, cs) or_return
                    write_skip(cw, 6, cs) or_return
                    write(cw, tag.tag_color[2], cs) or_return
                    write(cw, tag.tag_color[1], cs) or_return
                    write(cw, tag.tag_color[0], cs) or_return
                    write(cw, BYTE(0), cs) or_return
                    write(cw, tag.name, cs) or_return
                }

            case Palette_Chunk:
                write(cw, DWORD(len(val.entries)), cs) or_return
                write(cw, val.first_index, cs) or_return
                write(cw, val.last_index, cs) or_return
                write_skip(cw, 8, cs) or_return

                for entry in val.entries {
                    if entry.name != nil {
                        write(cw, WORD(1), cs) or_return
                    } else {
                        write(cw, WORD(0), cs) or_return
                    }

                    write(cw, entry.color[3], cs) or_return
                    write(cw, entry.color[2], cs) or_return
                    write(cw, entry.color[1], cs) or_return
                    write(cw, entry.color[0], cs) or_return

                    #partial switch v in entry.name {
                    case string:
                        write(cw, v, cs) or_return
                    }
                }

            case User_Data_Chunk:
                flags: UD_Flags
                if val.text != nil {
                    flags += {.Text}
                }if val.color != nil {
                    flags += {.Color}
                }if val.maps != nil {
                    flags += {.Properties}                    
                }

                write(cw, transmute(DWORD)flags, cs) or_return

                #partial switch v in val.text {
                case string:
                    write(cw, v, cs) or_return
                }

                #partial switch v in val.color {
                case Color_RGBA:
                    write(cw, v[3], cs) or_return
                    write(cw, v[2], cs) or_return
                    write(cw, v[1], cs) or_return
                    write(cw, v[0], cs) or_return
                }

                #partial switch m in val.maps {
                case Properties_Map:
                    if !ud_map_warn {
                        log.warn("Writing User Data Maps isn't supported rn.")
                        ud_map_warn = true
                    }
                    write(cw, DWORD(8), cs) or_return
                    write(cw, DWORD(0), cs) or_return 

                    /*mb: bytes.Buffer
                    defer bytes.buffer_destroy(&mb)
                    mw, ok4 := io.to_writer(bytes.buffer_to_stream(&mb))
                    if !ok4 {
                        return file_size, .Unable_Make_Writer
                    }
                    map_size: int
                    ms := &map_size

                    write(mw, DWORD(len(m)), ms) or_return

                    for key, val in m {
                        write(mw, key, ms) or_return
                        val := val.(Properties)
                        //write(mw, val, ms) or_return
                        for name, type in val {
                            write(mw, name, ms) or_return
                            write(mw, type, ms) or_return
                        }
                    }

                    map_size += 4
                    write(cw, DWORD(map_size), cs) or_return
                    write(cw, mb.buf[:map_size-4], cs) or_return*/
                }

            case Slice_Chunk:
                write(cw, DWORD(len(val.keys)), cs) or_return
                write(cw, transmute(DWORD)val.flags, cs) or_return
                write(cw, DWORD(0), cs) or_return
                write(cw, val.name, cs) or_return

                for key in val.keys {
                    write(cw, key.frame_num, cs) or_return
                    write(cw, key.x, cs) or_return
                    write(cw, key.y, cs) or_return
                    write(cw, key.width, cs) or_return
                    write(cw, key.height, cs) or_return

                    #partial switch v in key.center {
                    case Slice_Center:
                        write(cw, v.x, cs) or_return
                        write(cw, v.y, cs) or_return
                        write(cw, v.width, cs) or_return
                        write(cw, v.height, cs) or_return
                    }

                    #partial switch v in key.pivot {
                    case Slice_Pivot:
                        write(cw, v.x, cs) or_return
                        write(cw, v.y, cs) or_return
                    }
                }

            case Tileset_Chunk:
                write(cw, val.id, cs) or_return
                write(cw, transmute(DWORD)val.flags, cs) or_return
                write(cw, val.num_of_tiles, cs) or_return
                write(cw, val.width, cs) or_return
                write(cw, val.height, cs) or_return
                write(cw, val.base_index, cs) or_return
                write_skip(cw, 14, cs) or_return
                write(cw, val.name, cs) or_return

                #partial switch v in val.external {
                case Tileset_External:
                    write(cw, v.file_id, cs) or_return
                    write(cw, v.tileset_id, cs) or_return
                }

                #partial switch v in val.compressed {
                case Tileset_Compressed:
                    com_buf := make([]byte, len(v), allocator) or_return
                    defer delete(com_buf)
                    data_rd: [^]u8 = raw_data(v[:])
                    com_buf_rd: [^]u8 = raw_data(com_buf[:])

                    config := zlib.z_stream {
                        avail_in=zlib.uInt(len(v)), 
                        next_in=&data_rd[0],
                        avail_out=zlib.uInt(len(v)),
                        next_out=&com_buf_rd[0],
                    }
                    
                    en := zlib.deflateInit(&config, zlib.DEFAULT_COMPRESSION)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflate(&config, zlib.FINISH)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }
                    en = zlib.deflateEnd(&config)
                    if en < zlib.OK {
                        return file_size, ZLIB_Errors(en)
                    }

                    write(cw, DWORD(config.total_out), cs) or_return
                    write(cw, com_buf[:int(config.total_out)], cs) or_return
                }

            case:
                return file_size, .Invalid_Chunk_Type
            }
            write(fw, DWORD(chunk_size + 4), fs) or_return
            write(fw, cb.buf[:chunk_size], fs) or_return
        }
        write(w, DWORD(frame_size + 4), s) or_return
        write(w, fb.buf[:frame_size], s) or_return
    }

    written: int
    file_size += 4
    write(ww, DWORD(file_size), &written) or_return
    write(ww, b.buf[:file_size-4], &written) or_return
    if written != file_size {
        return file_size, Marshal_Errors.Wrong_Write_Size
    }
    return
}