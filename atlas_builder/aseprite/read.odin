package aseprite_file_handler

import "base:runtime"
import "core:io"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:math/fixed"
import "core:encoding/endian"

read_bool :: proc(r: io.Reader, n: ^int) -> (data: bool, err: Read_Error) {
    return bool(read_byte(r, n) or_return), nil
}

read_i8 :: proc(r: io.Reader, n: ^int) -> (data: i8, err: Read_Error) {
    return i8(read_byte(r, n) or_return), nil
}

read_byte :: proc(r: io.Reader, n: ^int) -> (data: BYTE, err: Read_Error) {
    return io.read_byte(r, n)
}

read_word :: proc(r: io.Reader, n: ^int) -> (data: WORD, err: Read_Error) { 
    buf: [2]byte
    s := io.read(r, buf[:], n) or_return
    if s != 2 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err
}

read_short :: proc(r: io.Reader, n: ^int) -> (data: SHORT, err: Read_Error) { 
    buf: [2]byte
    s := io.read(r, buf[:], n) or_return
    if s != 2 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_i16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err
}

read_dword :: proc(r: io.Reader, n: ^int) -> (data: DWORD, err: Read_Error) { 
    buf: [4]byte
    s := io.read(r, buf[:], n) or_return
    if s != 4 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }   return v, err 
}

read_long :: proc(r: io.Reader, n: ^int) -> (data: LONG, err: Read_Error) { 
    buf: [4]byte
    s := io.read(r, buf[:], n) or_return
    if s != 4 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_i32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_fixed :: proc(r: io.Reader, n: ^int) -> (data: FIXED, err: Read_Error) { 
    buf: [4]byte
    s := io.read(r, buf[:], n) or_return
    if s != 4 {
        return data, .Wrong_Read_Size
    }

    v, ok := endian.get_i32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
        return
    }
    data.i = v
    return 
}

read_float :: proc(r: io.Reader, n: ^int) -> (data: FLOAT, err: Read_Error) {
    buf: [4]byte 
    s := io.read(r, buf[:], n) or_return
    if s !=42 {
        return 0, .Wrong_Read_Size
    }
    
    v, ok := endian.get_f32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_double :: proc(r: io.Reader, n: ^int) -> (data: DOUBLE, err: Read_Error) {
    buf: [8]byte 
    s := io.read(r, buf[:], n) or_return
    if s != 8 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_f64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_qword :: proc(r: io.Reader, n: ^int) -> (data: QWORD, err: Read_Error) { 
    buf: [8]byte
    s := io.read(r, buf[:], n) or_return
    if s != 8 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_long64 :: proc(r: io.Reader, n: ^int) -> (data: LONG64, err: Read_Error) {
    buf: [8]byte
    s := io.read(r, buf[:], n) or_return
    if s != 8 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_i64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_string :: proc(r: io.Reader, n: ^int, allocator: runtime.Allocator, loc := #caller_location) -> (data: STRING, err: Read_Error) {
    size := int(read_word(r, n) or_return)

    buf := make([]byte, size, allocator, loc) or_return
    s := io.read(r, buf[:], n) or_return
    if s != size {
        err = .Wrong_Read_Size
        return
    }

    data = string(buf[:])
    return
}

read_point :: proc(r: io.Reader, n: ^int) -> (data: POINT, err: Read_Error) { 
    data.x = read_long(r, n) or_return
    data.y = read_long(r, n) or_return
    return 
}

read_size :: proc(r: io.Reader, n: ^int) -> (data: SIZE, err: Read_Error) {
    data.w = read_long(r, n) or_return
    data.h = read_long(r, n) or_return 
    return 
}

read_rect :: proc(r: io.Reader, n: ^int) -> (data: RECT, err: Read_Error) { 
    data.origin = read_point(r, n) or_return
    data.size = read_size(r, n) or_return
    return 
}

read_uuid:: proc(r: io.Reader, data: UUID, n: ^int) -> (err: Read_Error) { 
    s := io.read(r, cast([]u8)data[:], n) or_return
    if s != 16 {
        err = .Wrong_Read_Size
    }
    return 
}

read_pixel :: proc(r: io.Reader, n: ^int) -> (data: PIXEL, err: Read_Error) { 
    return read_byte(r, n)
}

read_pixels :: proc(r: io.Reader, data: []PIXEL, n: ^int) -> (err: Read_Error) {
    return read_bytes(r, data[:], n)
}

read_tile :: proc(r: io.Reader, type: Tile_ID, n: ^int) -> (data: TILE, err: Read_Error) { 
    switch type {
    case .byte:
        data = read_byte(r, n) or_return
    case .word:
        data = read_word(r, n) or_return
    case .dword:
        data = read_dword(r, n) or_return
    }
    return 
}

read_tiles :: proc(r: io.Reader, data: []TILE, type: Tile_ID, n: ^int) -> (err: Read_Error) {
    size := len(data)
    if len(data) == 0 {
        return
    }
    for i in 0..<size {
        data[i] = read_tile(r, type, n) or_return
    }
    return 
}

read_bytes :: proc(r: io.Reader, data: []byte, n: ^int) -> (err: Read_Error) {
    s := io.read(r, data[:], n) or_return
    if s != len(data) {
        log.error("Could read all the bytes asked.", s, len(data))
        err = .Wrong_Read_Size
    }
    return 
}

read_skip :: proc(r: io.Reader, to_skip: int, n: ^int) -> (err: Read_Error) {
    for _ in 0..<to_skip {
        io.read_byte(r, n) or_return
    }
    return
}

read_ud_value :: proc(r: io.Reader, type: Property_Type, n: ^int, allocator: runtime.Allocator) -> (val: Property_Value, err: Unmarshal_Error) {
    switch type {
    case .Null:   return nil, nil
    case .Bool:   return read_bool(r, n)
    case .I8:     return read_i8(r, n)
    case .U8:     return read_byte(r, n)
    case .I16:    return read_short(r, n)
    case .U16:    return read_word(r, n)
    case .I32:    return read_long(r, n)
    case .U32:    return read_dword(r, n)
    case .I64:    return read_long64(r, n)
    case .U64:    return read_qword(r, n)
    case .Fixed:  return read_fixed(r, n)
    case .F32:    return read_float(r, n)
    case .F64:    return read_double(r, n)
    case .String: return read_string(r, n, allocator)
    case .Point:  return read_point(r, n)
    case .Size:   return read_size(r, n)
    case .Rect:   return read_rect(r, n)
    case .UUID:
        val = make(UUID, 16, allocator) or_return
        read_uuid(r, val.(UUID)[:], n) or_return

    case .Vector:
        num := int(read_dword(r, n) or_return)
        val = make(UD_Vec, num, allocator) or_return
        vec_type := Property_Type(read_word(r, n) or_return)

        if vec_type == .Null {
            for i in 0..<num {
                type := Property_Type(read_word(r, n) or_return)
                val.(UD_Vec)[i] = read_ud_value(r, type, n, allocator) or_return
            }
        } else {
            for i in 0..<num {
                val.(UD_Vec)[i] = read_ud_value(r, vec_type, n, allocator) or_return
            }
        }

    case .Properties:
        size := read_dword(r, n) or_return
        // FIXME: Is leaking. Not writing data?
        val = make(Properties, size, allocator) or_return

        #partial switch &v in val {
        case Properties:
            for _ in 0..<size {
                key := read_string(r, n, allocator) or_return
                defer delete(key)
                type := Property_Type(read_word(r, n) or_return)
                v[key] = read_ud_value(r, type, n, allocator) or_return
            }
        }
    }
    return
}