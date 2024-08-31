package aseprite_file_handler

import "core:io"
import "core:fmt"
import "core:log"
import "core:encoding/endian"
_::fmt
_::log

write_bool :: proc(w: io.Writer, data: bool, size: ^int) -> (written: int, err: Write_Error) { 
    return write_byte(w, u8(data), size)
}

write_i8 :: proc(w: io.Writer, data: i8, size: ^int) -> (written: int, err: Write_Error) { 
    return write_byte(w, u8(data), size)
}

write_byte :: proc(w: io.Writer, data: BYTE, size: ^int) -> (written: int, err: Write_Error) { 
    return 1, io.write_byte(w, data, size)
}

write_word :: proc(w: io.Writer, data: WORD, size: ^int) -> (written: int, err: Write_Error) { 
    buf: [2]byte
    if !endian.put_u16(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 2 {
        err = .Wrong_Write_Size
    }
    return
}

write_short :: proc(w: io.Writer, data: SHORT, size: ^int) -> (written: int, err: Write_Error) {
    buf: [2]byte
    if !endian.put_i16(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 2 {
        err = .Wrong_Write_Size
    }
    return
}

write_dword :: proc(w: io.Writer, data: DWORD, size: ^int) -> (written: int, err: Write_Error) { 
    buf: [4]byte
    if !endian.put_u32(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_long :: proc(w: io.Writer, data: LONG, size: ^int) -> (written: int, err: Write_Error) { 
    buf: [4]byte
    if !endian.put_i32(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_fixed :: proc(w: io.Writer, data: FIXED, size: ^int) -> (written: int, err: Write_Error) { 
    return write(w, data.i, size)
}

write_float :: proc(w: io.Writer, data: FLOAT, size: ^int) -> (written: int, err: Write_Error) {
    buf: [4]byte 
    if !endian.put_f32(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_double :: proc(w: io.Writer, data: DOUBLE, size: ^int) -> (written: int, err: Write_Error) { 
    buf: [8]byte
    if !endian.put_f64(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_qword :: proc(w: io.Writer, data: QWORD, size: ^int) -> (written: int, err: Write_Error) { 
    buf: [8]byte
    if !endian.put_u64(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_long64 :: proc(w: io.Writer, data: LONG64, size: ^int) -> (written: int, err: Write_Error) {
    buf: [8]byte
    if !endian.put_i64(buf[:], .Little, data) {
        return written, .Unable_To_Encode_Data
    }

    written = io.write(w, buf[:], size) or_return
    if written != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_string :: proc(w: io.Writer, data: STRING, size: ^int) -> (written: int, err: Write_Error) {
    written = write_word(w, WORD(len(data)), size) or_return
    if written != 2 {
        return written, .Wrong_Write_Size
    }

    str := transmute([]u8)data
    //fmt.println(data, str)
    written += write_bytes(w, str[:], size) or_return
    if written != 2 + len(data) {
        err = .Wrong_Write_Size
    }
    return
}

write_point :: proc(w: io.Writer, data: POINT, size: ^int) -> (written: int, err: Write_Error) { 
    written = write_long(w, data.x, size) or_return
    if written != 4 {
        return written, .Wrong_Write_Size
    }
    written += write_long(w, data.y, size) or_return
    if written != 8 {
        return written, .Wrong_Write_Size
    }
    return
}

write_size :: proc(w: io.Writer, data: SIZE, size: ^int) -> (written: int, err: Write_Error) { 
    written = write_long(w, data.w, size) or_return
    if written != 4 {
        return written, .Wrong_Write_Size
    }
    written += write_long(w, data.h, size) or_return
    if written != 8 {
        return written, .Wrong_Write_Size
    }
    return
}

write_rect :: proc(w: io.Writer, data: RECT, size: ^int) -> (written: int, err: Write_Error) { 
    write_point(w, data.origin, size) or_return
    write_size(w, data.size, size) or_return
    return
}

write_uuid:: proc(w: io.Writer, data: UUID, size: ^int) -> (written: int, err: Write_Error) { 
    data := cast([]u8)data
    written = io.write(w, data[:], size) or_return
    if written != 16 {
        err = .Wrong_Write_Size
    }
    return
}

write_pixel :: proc(w: io.Writer, data: PIXEL, size: ^int) -> (written: int, err: Write_Error) {
    return write_byte(w, data, size)
}

write_pixels :: proc(w: io.Writer, data: []PIXEL, size: ^int) -> (written: int, err: Write_Error) {
    return write_bytes(w, data[:], size)
}

write_tile :: proc(w: io.Writer, data: TILE, size: ^int) -> (written: int, err: Write_Error) { 
    switch v in data {
    case BYTE:
        written = write_byte(w, v, size) or_return
    case WORD:
        written = write_word(w, v, size) or_return
    case DWORD:
        written = write_dword(w, v, size) or_return
    }
    return  
}

write_tiles :: proc(w: io.Writer, data: []TILE, size: ^int) -> (written: int, err: Write_Error) {
    if len(data) == 0 {
        return 0, .Array_To_Small
    }

    for tile in data {
        switch v in tile {
        case BYTE:
            written += write_byte(w, v, size) or_return
        case WORD:
            written += write_word(w, v, size) or_return
        case DWORD:
            written += write_dword(w, v, size) or_return
        }
    }
    return 
}

write_bytes :: proc(w: io.Writer, data: []u8, size: ^int) -> (written: int, err: Write_Error) {
    written, err = io.write(w, data[:], size)
    if err != nil {
        log.error("Failed to write bytes", data[:], string(data[:]), written, size^)
        return
    }
    if written != len(data) {
        err = .Wrong_Write_Size
    }
    return 
}

write_skip :: proc(w: io.Writer, to_skip: int, size: ^int) -> (written: int, err: Write_Error) {
    for _ in 0..<to_skip {
        io.write_byte(w, 0x0, size) or_return
        written += 1
    }
    if written != to_skip {
        err = .Wrong_Write_Size
    }
    return
}

write_ud_value :: proc(w: io.Writer, data: Property_Value, size: ^int) -> (err: Marshal_Error) {
    switch v in data {
    case nil:
    case bool:   write(w, v, size) or_return
    case i8:     write(w, v, size) or_return
    case BYTE:   write(w, v, size) or_return
    case SHORT:  write(w, v, size) or_return
    case WORD:   write(w, v, size) or_return
    case LONG:   write(w, v, size) or_return
    case DWORD:  write(w, v, size) or_return
    case LONG64: write(w, v, size) or_return
    case QWORD:  write(w, v, size) or_return
    case FIXED:  write(w, v, size) or_return
    case FLOAT:  write(w, v, size) or_return
    case DOUBLE: write(w, v, size) or_return
    case STRING: write(w, v, size) or_return
    case POINT:  write(w, v, size) or_return
    case SIZE:   write(w, v, size) or_return
    case RECT:   write(w, v, size) or_return
    case UUID:   write(w, v, size) or_return
    case UD_Vec:
        write(w, DWORD(len(v)), size) or_return
        write(w, WORD(0x0), size) or_return
        for value in v {
            type := get_property_type(value) or_return
            write(w, type, size) or_return
            write(w, value, size) or_return
        }
    case Properties:
        write(w, DWORD(len(v)), size) or_return
        for key, val in v {
            write(w, key, size) or_return
            type := get_property_type(val) or_return
            write(w, type, size) or_return
            write(w, val, size) or_return
        }
    }
    return
}

write :: proc{
    write_bool, write_i8, write_byte, write_word, write_short, write_dword,  
    write_long, write_fixed, write_float, write_double, write_qword,  
    write_long64, write_string, write_point, write_size, write_rect,
    write_uuid, write_tile, write_bytes, write_skip, write_ud_value,
}
