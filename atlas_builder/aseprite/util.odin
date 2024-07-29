package aseprite_file_handler

import "core:log"
import "core:reflect"
import "core:encoding/endian"

get_chunk_type :: proc(c: Chunk) -> (type: WORD, err: Marshal_Error) {
    switch _ in c {
    case Old_Palette_256_Chunk:
        type = WORD(Chunk_Types.old_palette_256)
    case Old_Palette_64_Chunk:
        type = WORD(Chunk_Types.old_palette_64)
    case Layer_Chunk:
        type = WORD(Chunk_Types.layer)
    case Cel_Chunk:
        type = WORD(Chunk_Types.cel)
    case Cel_Extra_Chunk:
        type = WORD(Chunk_Types.cel_extra)
    case Color_Profile_Chunk:
        type = WORD(Chunk_Types.color_profile)
    case External_Files_Chunk:
        type = WORD(Chunk_Types.external_files)
    case Mask_Chunk:
        type = WORD(Chunk_Types.mask)
    case Path_Chunk:
        type = WORD(Chunk_Types.path)
    case Tags_Chunk:
        type = WORD(Chunk_Types.tags)
    case Palette_Chunk:
        type = WORD(Chunk_Types.palette)
    case User_Data_Chunk:
        type = WORD(Chunk_Types.user_data)
    case Slice_Chunk:
        type = WORD(Chunk_Types.slice)
    case Tileset_Chunk:
        type = WORD(Chunk_Types.tileset)
    case:
        err = .Invalid_Chunk_Type
    }
    return
}

get_cel_type :: proc(c: Cel_Type) -> (type: WORD, err: Marshal_Error) {
    switch _ in c {
        case Raw_Cel:
            type = WORD(Cel_Types.Raw)
        case Linked_Cel:
            type = WORD(Cel_Types.Linked_Cel)
        case Com_Image_Cel:
            type = WORD(Cel_Types.Compressed_Image)
        case Com_Tilemap_Cel:
            type = WORD(Cel_Types.Compressed_Tilemap)
        case:
            err = .Invalid_Cel_Type
    }
    return
}

get_property_type :: proc(v: Property_Value) -> (type: WORD, err: Marshal_Error) {
    switch t in v {
    case nil:        type = WORD(Property_Type.Null)
    case bool:       type = WORD(Property_Type.Bool)
    case i8:         type = WORD(Property_Type.I8)
    case BYTE:       type = WORD(Property_Type.U8)
    case SHORT:      type = WORD(Property_Type.I16)
    case WORD:       type = WORD(Property_Type.U16)
    case LONG:       type = WORD(Property_Type.I32)
    case DWORD:      type = WORD(Property_Type.U32)
    case LONG64:     type = WORD(Property_Type.I64)
    case QWORD:      type = WORD(Property_Type.U64)
    case FIXED:      type = WORD(Property_Type.Fixed)
    case FLOAT:      type = WORD(Property_Type.F32)
    case DOUBLE:     type = WORD(Property_Type.F64)
    case STRING:     type = WORD(Property_Type.String)
    case POINT:      type = WORD(Property_Type.Point)
    case SIZE:       type = WORD(Property_Type.Size)
    case RECT:       type = WORD(Property_Type.Rect)
    case UUID:       type = WORD(Property_Type.UUID)
    case UD_Vec:     type = WORD(Property_Type.Vector)
    case Properties: type = WORD(Property_Type.Properties)
    case:             err = Marshal_Errors.Invalid_Property_Type
    }
    return
}

tiles_to_u8 :: proc(tiles: []TILE, b: []u8) -> (pos: int, err: Write_Error) {
    next: int
    for t in tiles {
        switch v in t {
        case BYTE:
            pos = next
            next += size_of(BYTE)
            b[pos] = v
        case WORD:
            pos = next
            next += size_of(WORD)
            if !endian.put_u16(b[pos:next], .Little, v) {
                return 0, .Unable_To_Encode_Data
            }
        case DWORD:
            pos = next
            next += size_of(DWORD)
            if !endian.put_u32(b[pos:next], .Little, v) {
                return 0, .Unable_To_Encode_Data
            }
        }
    }
    pos = next
    return
}

chunk_equal :: proc(x, y: Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    switch xv in x {
    case Old_Palette_256_Chunk:
        yv, ok := y.(Old_Palette_256_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Old_Palette_64_Chunk:
        yv, ok := y.(Old_Palette_64_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Layer_Chunk:
        yv, ok := y.(Layer_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Chunk:
        yv, ok := y.(Cel_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Extra_Chunk:
        yv, ok := y.(Cel_Extra_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case External_Files_Chunk:
        yv, ok := y.(External_Files_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Mask_Chunk:
        yv, ok := y.(Mask_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Path_Chunk:
        yv, ok := y.(Path_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Tags_Chunk:
        yv, ok := y.(Tags_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Palette_Chunk:
        yv, ok := y.(Palette_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Color_Profile_Chunk:
        yv, ok := y.(Color_Profile_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case User_Data_Chunk:
        yv, ok := y.(User_Data_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Slice_Chunk:
        yv, ok := y.(Slice_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Tileset_Chunk:
        yv, ok := y.(Tileset_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case nil:
        if y != nil {
            return x, y, typeid_of(Chunk), false
        }
    case:
        return
    }

    eq = true
    return
}

frame_equal :: proc(x, y: Frame) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header { 
        return x.header, y.header, typeid_of(Document), false
    }
    if len(x.chunks) != len(y.chunks) {
        return len(x.chunks), len(y.chunks), typeid_of(Document), false
    }
    for i in 0..<len(x.chunks) {
        xc, yc := x.chunks[i], y.chunks[i]
        a, b, c, eq = chunk_equal(xc, yc)
        if !eq { return }
    }
    eq = true
    return
}

document_equal :: proc(x, y: Document) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header {
        if x.header.size == y.header.size {
            return x.header, y.header, typeid_of(Document), false
        }
        //log.warn("File sizes are differant:", x.header.size, y.header.size)
    }
    if len(x.frames) != len(y.frames) {
        return len(x.frames), len(y.frames), typeid_of(Document), false
    }
    for i in 0..<len(x.frames) {
        xf, yf := x.frames[i], y.frames[i]
        a, b, c, eq = frame_equal(xf, yf)
        if !eq { return }
    }
    eq = true
    return
}
