package aseprite_file_handler

import "base:intrinsics"
import "core:io"
import "core:os"
import "core:fmt"
import "core:log"
import "core:bytes"
import "core:bufio"
_::fmt
_::log


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
    if err_no != nil {
        log.error("Unable to read because of:", err_no)
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
    // TODO: Put Everything into a Virtual Arena?
    // But I do prefer letting user choose the allocator.
    context.allocator = allocator
    icc_warn: bool
    rt := &total_read

    doc.header = read_file_header(r, rt) or_return
    frames := doc.header.frames
    color_depth := doc.header.color_depth
    doc.frames = make([]Frame, int(frames)) or_return

    for &frame in doc.frames {
        fh: Frame_Header
        //frame_size := read_dword(r, rt) or_return
        read_dword(r, rt) or_return
        frame_magic := read_word(r, rt) or_return
        if frame_magic != FRAME_MAGIC_NUM {
            return total_read, .Bad_Frame_Magic_Number
        }
        fh.old_num_of_chunks = read_word(r, rt) or_return
        fh.duration = read_word(r, rt) or_return
        if fh.duration == 0 {
            fh.duration = doc.header.speed
        }
        
        read_skip(r, 2, rt) or_return
        fh.num_of_chunks = read_dword(r, rt) or_return

        chunks := int(fh.num_of_chunks) 
        if chunks == 0 {
            chunks = int(fh.old_num_of_chunks)
        }

        frame.header = fh
        frame.chunks = make([]Chunk, chunks) or_return

        for &chunk in frame.chunks {
            c_size := int(read_dword(r, rt) or_return)
            c_type := cast(Chunk_Types)read_word(r, rt) or_return

            switch c_type {
            case .old_palette_256:
                chunk = read_old_palette_256(r, rt) or_return

            case .old_palette_64:
                chunk = read_old_palette_64(r, rt) or_return

            case .layer:
                chunk = read_layer(r, rt) or_return

            case .cel:
                chunk = read_cel(r, rt, int(color_depth), c_size) or_return

            case .cel_extra:
                chunk = read_cel_extra(r, rt) or_return

            case .color_profile:
                chunk = read_color_profile(r, rt, &icc_warn) or_return

            case .external_files:
                chunk = read_external_files(r, rt) or_return

            case .mask:
                chunk = read_mask(r, rt) or_return

            case .path:
                chunk = read_path()

            case .tags:
                chunk = read_tags(r, rt) or_return

            case .palette:
                chunk = read_palette(r, rt) or_return

            case .user_data:
                chunk = read_user_data(r, rt) or_return

            case .slice:
                chunk = read_slice(r, rt) or_return

            case .tileset:
                chunk = read_tileset(r, rt) or_return

            case .none:
                fallthrough
            case:
                log.error("Invalid Chunk Type", c_type)
                return total_read, .Invalid_Chunk_Type
            }
        }
    }
    return
}


unmarshal_chunks :: proc{unmarshal_multi_chunks, unmarshal_single_chunk}

//@(warning="This function is new. May have bugs.")
unmarshal_multi_chunks :: proc(r: io.Reader, buf: ^[dynamic]Chunk, chunks: Chunk_Set, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error) {
    context.allocator = allocator
    icc_warn: bool
    rt := &total_read

    size := read_dword(r, rt) or_return
    if io.Stream_Mode.Size in io.query(r) {
        stream_size := io.size(r) or_return
        if stream_size != i64(size) {
            return total_read, .Data_Size_Not_Equal_To_Header
        }
    }

    magic := read_word(r, rt) or_return
    if magic != FILE_MAGIC_NUM {
        return total_read, .Bad_File_Magic_Number
    } 

    frames := read_word(r, rt) or_return
    read_skip(r, 4, rt) or_return
    color_depth := int(read_word(r, rt) or_return)
    read_skip(r, 114, rt) or_return

    for _ in 0..<frames {
        read_dword(r, rt) or_return
        frame_magic := read_word(r, rt) or_return
        if frame_magic != FRAME_MAGIC_NUM {
            return total_read, .Bad_Frame_Magic_Number
        }
        old_num_of_chunks := read_word(r, rt) or_return
        read_skip(r, 4, rt) or_return
        num_of_chunks := int(read_dword(r, rt) or_return)

        if num_of_chunks == 0 {
            num_of_chunks = int(old_num_of_chunks)
        }
        
        for _ in 0..<num_of_chunks {
            c_size := int(read_dword(r, rt) or_return)
            c_type := cast(Chunk_Types)read_word(r, rt) or_return
            chunk: Chunk
            switch c_type {
            case .old_palette_256:
                if .old_palette_256 in chunks {
                    chunk = read_old_palette_256(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .old_palette_64:
                if .old_palette_64 in chunks {
                    chunk = read_old_palette_64(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .layer:
                if .layer in chunks {
                    chunk = read_layer(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .cel:
                if .cel in chunks {
                    chunk = read_cel(r, rt, color_depth, c_size) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .cel_extra:
                if .cel_extra in chunks {
                    chunk = read_cel_extra(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .color_profile:
                if .color_profile in chunks {
                    chunk = read_color_profile(r, rt, &icc_warn) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .external_files:
                if .external_files in chunks {
                    chunk = read_external_files(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .mask:
                if .mask in chunks {
                    chunk = read_mask(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .path:
                if .path in chunks {
                    chunk = read_path()
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .tags:
                if .tags in chunks {
                    chunk = read_tags(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .palette:
                if .palette in chunks {
                    chunk = read_palette(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .user_data:
                if .user_data in chunks {
                    chunk = read_user_data(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .slice:
                if .slice in chunks {
                    chunk = read_slice(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .tileset:
                if .tileset in chunks {
                    chunk = read_tileset(r, rt) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .none:
                fallthrough
            case:
                log.error("Invalid Chunk Type", c_type)
                return total_read, .Invalid_Chunk_Type
            }
            if chunk != nil {
                append(buf, chunk) or_return
            }
        }
    }
    return
}


//@(warning="This function is new. May have bugs.")
unmarshal_single_chunk :: proc(r: io.Reader, buf: ^[dynamic]$T, allocator := context.allocator) -> (total_read: int, err: Unmarshal_Error)
where intrinsics.type_is_variant_of(Chunk, T) {
    context.allocator = allocator
    icc_warn: bool
    _ = icc_warn
    rt := &total_read

    size := read_dword(r, rt) or_return
    if io.Stream_Mode.Size in io.query(r) {
        stream_size := io.size(r) or_return
        if stream_size != i64(size) {
            return total_read, .Data_Size_Not_Equal_To_Header
        }
    }

    magic := read_word(r, rt) or_return
    if magic != FILE_MAGIC_NUM {
        return total_read, .Bad_File_Magic_Number
    } 

    frames := read_word(r, rt) or_return
    read_skip(r, 4, rt) or_return
    color_depth := int(read_word(r, rt) or_return)
    _ = color_depth
    read_skip(r, 114, rt) or_return

    for _ in 0..<frames {
        read_dword(r, rt) or_return
        frame_magic := read_word(r, rt) or_return
        if frame_magic != FRAME_MAGIC_NUM {
            return total_read, .Bad_Frame_Magic_Number
        }
        old_num_of_chunks := read_word(r, rt) or_return
        read_skip(r, 4, rt) or_return
        num_of_chunks := int(read_dword(r, rt) or_return)

        if num_of_chunks == 0 {
            num_of_chunks = int(old_num_of_chunks)
        }
        when T == Old_Palette_256_Chunk {}
        
        for _ in 0..<num_of_chunks {
            c_size := int(read_dword(r, rt) or_return)
            _ = c_size
            c_type := cast(Chunk_Types)read_word(r, rt) or_return

            // TODO: This is too dirty for my likeing. Make a proc group for it all.
            switch c_type {
            case .old_palette_256: 
                when T == Old_Palette_256_Chunk {
                    append(buf, read_old_palette_256(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .old_palette_64:
                when T == Old_Palette_64_Chunk {
                    append(buf, read_old_palette_64(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .layer:
                when T == Layer_Chunk {
                    append(buf, read_layer(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .cel:
                when T == Cel_Chunk {
                    append(buf, read_cel(r, rt, color_depth, c_size) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .cel_extra:
                when T == Cel_Extra_Chunk {
                    append(buf, read_cel_extra(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .color_profile:
                when T == Color_Profile_Chunk {
                    append(buf, read_color_profile(r, rt, &icc_warn) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .external_files:
                when T == External_Files_Chunk {
                    append(buf, read_external_files(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .mask:
                when T == Mask_Chunk {
                    append(buf, read_mask(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .path:
                when T == Path_Chunk {
                    append(buf, read_path()) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .tags:
                when T == Tags_Chunk {
                    append(buf, read_tags(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .palette:
                when T == Palette_Chunk {
                    append(buf, read_palette(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .user_data:
                when T == User_Data_Chunk {
                    append(buf, read_user_data(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .slice:
                when T == Slice_Chunk {
                    append(buf, read_slice(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .tileset:
                when T == Tileset_Chunk {
                    append(buf, read_tileset(r, rt) or_return) or_return
                } else { 
                    read_skip(r, c_size-6, rt) or_return 
                }
            case .none: fallthrough
            case:
                log.error("Invalid Chunk Type", c_type)
                return total_read, .Invalid_Chunk_Type
            }
        }
    }
    return
}
