//+private
package aseprite_file_handler

import "core:fmt"
import "core:log"
import "core:slice"
import "core:reflect"

_old_palette_256_equal :: proc(x, y: Old_Palette_256_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if len(x) != len(y) {
        return len(x), len(y), typeid_of(Old_Palette_256_Chunk), false
    }
    for i in 0..<len(x) {
        xp, yp := x[i], y[i]

        if xp.num_colors != yp.num_colors {
            return xp.num_colors, yp.num_colors, typeid_of(Old_Palette_Packet), false
        }
        if xp.entries_to_skip != yp.entries_to_skip{
            return xp.entries_to_skip, yp.entries_to_skip, typeid_of(Old_Palette_Packet), false
        }
        if len(xp.colors) != len(yp.colors){
            return len(xp.colors), len(yp.colors), typeid_of(Old_Palette_Packet), false
        }

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return xc, yc, typeid_of(Old_Palette_Packet), false
            }
        }
    }
    eq = true
    return
}

_old_plette_64_equal :: proc(x, y: Old_Palette_64_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if len(x) != len(y) {
        return len(x), len(y), typeid_of(Old_Palette_256_Chunk), false
    }
    for i in 0..<len(x) {
        xp, yp := x[i], y[i]

        if xp.num_colors != yp.num_colors {
            return xp.num_colors, yp.num_colors, typeid_of(Old_Palette_Packet), false
        }
        if xp.entries_to_skip != yp.entries_to_skip{
            return xp.entries_to_skip, yp.entries_to_skip, typeid_of(Old_Palette_Packet), false
        }
        if len(xp.colors) != len(yp.colors){
            return len(xp.colors), len(yp.colors), typeid_of(Old_Palette_Packet), false
        }

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return xc, yc, typeid_of(Old_Palette_Packet), false
            }
        }
    }
    eq = true
    return
}

_layer_equal :: proc(x, y: Layer_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.type != y.type {
        return x.type, y.type, typeid_of(Layer_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Layer_Chunk), false
    } 
    if x.opacity != y.opacity {
        return x.opacity, y.opacity, typeid_of(Layer_Chunk), false
    } 
    if x.blend_mode != y.blend_mode {
        return x.blend_mode, y.blend_mode, typeid_of(Layer_Chunk), false
    }
    if x.child_level != y.child_level {
        return x.child_level, y.child_level, typeid_of(Layer_Chunk), false
    }
    if x.default_width != y.default_width {
        return x.default_width, y.default_width, typeid_of(Layer_Chunk), false
    }
    if x.tileset_index != y.tileset_index {
        return x.tileset_index, y.tileset_index, typeid_of(Layer_Chunk), false
    }
    if x.default_height != y.default_height {
        return x.default_height, y.default_height, typeid_of(Layer_Chunk), false
    }
    if x.name != y.name {
        return x.name, y.name, typeid_of(Layer_Chunk), false
    }

    eq = true
    return 
}

_cel_equal :: proc(x, y: Cel_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.x != y.x {
        return y.x, y.x, typeid_of(Cel_Chunk), false
    } 
    if y.y != x.y {
        return x.y, y.y, typeid_of(Cel_Chunk), false
    } 
    if x.type != y.type {
        return x.type, y.type , typeid_of(Cel_Chunk), false
    }
    if x.z_index != y.z_index {
        return x.z_index, y.z_index, typeid_of(Cel_Chunk), false
    }
    if x.layer_index != y.layer_index {
        return x.layer_index, y.layer_index, typeid_of(Cel_Chunk), false
    }
    if x.opacity_level != y.opacity_level {
        return x.opacity_level, y.opacity_level, typeid_of(Cel_Chunk), false
    }

    switch xv in x.cel {
    case Raw_Cel:
        yv, ok := y.cel.(Raw_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Raw_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Raw_Cel), false
        }
        if !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return xv.pixel[:], yv.pixel[:], typeid_of(Raw_Cel), false
        }

    case Linked_Cel:
        yv, ok := y.cel.(Linked_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv != yv {
            return xv, yv, typeid_of(Linked_Cel), false
        }

    case Com_Image_Cel:
        yv, ok := y.cel.(Com_Image_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Com_Image_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Com_Image_Cel), false
        }
        if !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return xv.pixel[:], yv.pixel[:], typeid_of(Com_Image_Cel), false
        }

    case Com_Tilemap_Cel:
        yv, ok := y.cel.(Com_Tilemap_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_x != yv.bitmask_x {
            return xv.bitmask_x, yv.bitmask_x, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_y != yv.bitmask_y {
            return xv.bitmask_y, yv.bitmask_y, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_id != yv.bitmask_id {
            return xv.bitmask_id, yv.bitmask_id, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bits_per_tile != yv.bits_per_tile {
            return xv.bits_per_tile, yv.bits_per_tile, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_diagonal != yv.bitmask_diagonal {
            return xv.bitmask_diagonal, yv.bitmask_diagonal, typeid_of(Com_Tilemap_Cel), false
        }
        // TODO: Might not compare right.
        if !slice.equal(xv.tiles[:], yv.tiles[:]) {
            return xv.tiles[:], yv.tiles[:], typeid_of(Com_Tilemap_Cel), false
        }

    case nil:
        if y.cel != nil {
            return x.cel, y.cel, typeid_of(Cel_Type), false
        }

    case:
        return x.cel, y.cel, typeid_of(Cel_Type), false
    }
    eq = true
    return
}

_cel_extra_equal :: proc(x, y: Cel_Extra_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x != y { 
        return x, y, typeid_of(Cel_Extra_Chunk), false 
    }
    eq = true
    return 
}

_color_profile_equal :: proc(x, y: Color_Profile_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.type != y.type {
        return x.type, y.type, typeid_of(Color_Profile_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Color_Profile_Chunk), false
    }
    if x.fixed_gamma != y.fixed_gamma {
        return x.fixed_gamma, y.fixed_gamma, typeid_of(Color_Profile_Chunk), false
    }

    switch xv in x.icc {
    case ICC_Profile:
        yv, ok := y.icc.(ICC_Profile)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Color_Profile_Chunk), false
        }
        if !slice.equal(xv[:], yv[:]) {
            return xv[:], yv[:], typeid_of(ICC_Profile), false
        }
    case nil:
        if y.icc != nil {
            return xv, reflect.union_variant_typeid(y), typeid_of(Color_Profile_Chunk), false
        }
    case:
        return x.icc, y.icc, typeid_of(Color_Profile_Chunk), false
    }

    eq = true
    return 
}

_external_files_equal :: proc(x, y: External_Files_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if len(x) != len(y) {
        return len(x), len(y), typeid_of(External_Files_Chunk), false
    }

    for i in 0..<len(x) {
        xe, ye: External_Files_Entry = x[i], y[i]
        if xe.id != ye.id {
            return xe.id, ye.id, typeid_of(External_Files_Entry), false
        }
        if xe.type != ye.type {
            return xe.type,ye.type, typeid_of(External_Files_Entry), false
        }
        if xe.file_name_or_id != ye.file_name_or_id {
            return xe.file_name_or_id, ye.file_name_or_id, typeid_of(External_Files_Entry), false
        } 
    }
    eq = true
    return
}

_mask_equal :: proc(x, y: Mask_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.x != y.x {
        return x.x, y.x, typeid_of(Mask_Chunk), false
    } 
    if x.y != y.y {
        return x.y, y.y, typeid_of(Mask_Chunk), false
    }
    if x.width != y.width {
        return x.width, y.width, typeid_of(Mask_Chunk), false
    }
    if x.height != y.height {
        return x.height, y.height, typeid_of(Mask_Chunk), false
    }
    if x.name != y.name {
        return x.name, y.name, typeid_of(Mask_Chunk), false
    }
    if !slice.equal(x.bit_map_data[:], y.bit_map_data[:]) {
        return x.bit_map_data[:], y.bit_map_data[:], typeid_of(Mask_Chunk), false
    }
    eq = true
    return
}

_path_equal :: proc(x, y: Path_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x != y { 
        return x, y, typeid_of(Path_Chunk), false 
    }
    eq = true
    return 
}

_tags_equal :: proc(x, y: Tags_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if len(x) != len(y) {
        return len(x), len(y), typeid_of(Tags_Chunk), false
    }

    for i in 0..<len(x) {
        xt, yt: Tag = x[i], y[i]
        if xt.repeat != yt.repeat {
            return xt.repeat, yt.repeat, typeid_of(Tag), false
        } 
        if xt.to_frame != yt.to_frame {
            return xt.to_frame, yt.to_frame, typeid_of(Tag), false
        } 
        if xt.tag_color != yt.tag_color {
            return xt.tag_color, yt.tag_color, typeid_of(Tag), false
        }
        if xt.from_frame != yt.from_frame {
            return xt.from_frame, yt.from_frame, typeid_of(Tag), false
        }
        if xt.loop_direction != yt.loop_direction {
            return xt.loop_direction, yt.loop_direction, typeid_of(Tag), false
        }
        if xt.name != xt.name {
            return xt.name, xt.name, typeid_of(Tag), false
        }
        
    }
    eq = true
    return
}

_palette_equal :: proc(x, y: Palette_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.size != y.size {
        return x.size, y.size, typeid_of(Palette_Chunk), false
    } 
    if x.last_index != y.last_index {
        return x.last_index, y.last_index, typeid_of(Palette_Chunk), false
    }
    if x.first_index != y.first_index {
        return x.first_index, y.first_index, typeid_of(Palette_Chunk), false
    }
    if len(x.entries) != len(y.entries) {
        return len(x.entries), len(y.entries), typeid_of(Palette_Chunk), false
    }

    for i in 0..<len(x.entries) {
        xp, yp: Palette_Entry = x.entries[i], y.entries[i]
        if xp.color != yp.color {
            return xp.color, yp.color, typeid_of(Palette_Entry), false
        }
        if xp.name != xp.name {
            return xp.name, xp.name, typeid_of(Palette_Entry), false
        }
    }
    eq = true
    return
}

_ud_prop_val_eq :: proc(x,y: Property_Value) -> (a: any, b: any, c: typeid, eq: bool) {
    switch xv in x {
    case bool:
        yv, ok := y.(bool)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(bool), false
        } 
    case i8:
        yv, ok := y.(i8)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(i8), false
        }
    case BYTE:
        yv, ok := y.(BYTE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(BYTE), false
        }

    case SHORT:
        yv, ok := y.(SHORT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(SHORT), false
        }

    case WORD:
        yv, ok := y.(WORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(WORD), false
        }

    case LONG:
        yv, ok := y.(LONG)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(LONG), false
        }

    case DWORD:
        yv, ok := y.(DWORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(DWORD), false
        }

    case LONG64:
        yv, ok := y.(LONG64)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(LONG64), false
        }

    case QWORD:
        yv, ok := y.(QWORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(QWORD), false
        }

    case FIXED:
        yv, ok := y.(FIXED)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(FIXED), false
        }

    case FLOAT:
        yv, ok := y.(FLOAT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(FLOAT), false
        }

    case DOUBLE:
        yv, ok := y.(DOUBLE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(DOUBLE), false
        }

    case STRING:
        yv, ok := y.(STRING)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv == yv {
            return xv, yv, typeid_of(STRING), false
        }
        if xv != yv {
            return xv, yv, typeid_of(STRING), false
        } 

    case SIZE:
        yv, ok := y.(SIZE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(SIZE), false
        }

    case POINT:
        yv, ok := y.(POINT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(POINT), false
        }

    case RECT:
        yv, ok := y.(RECT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(RECT), false
        }

    case UUID:
        yv, ok := y.(UUID)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if !slice.equal(xv[:], yv[:]) {
            return xv, yv, typeid_of(UUID), false
        }

    case Properties:
        yv, ok := y.(Properties)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        return _ud_props_eq(xv, yv)

    case UD_Vec:
        yv, ok := y.(UD_Vec)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Property_Value), false
        }
        if len(xv) != len(yv) {
            return len(xv), len(yv), typeid_of(UD_Vec), false 
        }

        for p in 0..<len(xv) {
            a, b, c, eq = _ud_prop_val_eq(xv[p], yv[p])
            if !eq { return }
        }
        
    case nil:
        if y != nil {
            return x, y, typeid_of(Property_Value), false
        }
    case:
        return x, y, typeid_of(Property_Value), false
    }
    eq = true
    return
}

_ud_props_eq :: proc(x, y: Properties) -> (a: any, b: any, c: typeid, eq: bool) {
    if len(x) != len(y) {
        return len(x), len(y), typeid_of(Properties), false
    }

    if x == nil {
        return "Properties X", nil, typeid_of(User_Data_Chunk), false
    } else if y == nil {
        return nil, "Properties y", typeid_of(User_Data_Chunk), false
    }
    
    for key_x, val_x in x {
        val_y, ok := y[key_x]
        if !ok {
            fmt.println(key_x)
            return key_x, nil, typeid_of(Properties_Map), false
        }
        a, b, c, eq = _ud_prop_val_eq(val_x, val_y)
        if !eq { return }
    }
    eq = true
    return
}

_user_data_equal :: proc(x, y: User_Data_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.text != y.text {
        return x.text, y.text, typeid_of(User_Data_Chunk), false
    }
    if x.color != y.color {
        return x.color, y.color, typeid_of(User_Data_Chunk), false
    }
    //log.info("Properties Map check's been temporarily removed.")
    if x.maps == nil && y.maps == nil {
        eq = true
        return
    } else if x.maps != nil && y.maps == nil {
        return "Properties Map X", nil, typeid_of(User_Data_Chunk), false
    } else if y.maps != nil && x.maps == nil {
        return nil, "Properties Map y", typeid_of(User_Data_Chunk), false
    }

    xm := x.maps.(Properties_Map)
    ym := y.maps.(Properties_Map)

    if len(xm) != len(ym) {
        return len(xm), len(ym), typeid_of(Properties), false
    }
    
    for key_x, val_x in xm {
        val_y, ok := ym[key_x]
        if !ok {
            fmt.println(key_x)
            return key_x, nil, typeid_of(Properties_Map), false
        }
        a, b, c, eq = _ud_prop_val_eq(val_x, val_y)
        if !eq { return }
    }
    eq = true
    return
}

_slice_equal :: proc(x, y: Slice_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Slice_Chunk), false
    }
    if x.name != x.name {
        return x.name, x.name, typeid_of(Slice_Chunk), false
    }
    if len(x.keys) != len(y.keys) {
        return len(x.keys), len(y.keys), typeid_of(Slice_Chunk), false
    }

    for i in 0..<len(x.keys) {
        xk, yk: Slice_Key = x.keys[i], y.keys[i]
        if xk != yk {
            return xk, yk, typeid_of(Slice_Key), false
        }
    }
    eq = true
    return
}

_tileset_equal :: proc(x, y: Tileset_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.id != y.id {
        return x.id, y.id, typeid_of(Tileset_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Tileset_Chunk), false
    }
    if x.num_of_tiles != y.num_of_tiles {
        return x.num_of_tiles, y.num_of_tiles, typeid_of(Tileset_Chunk), false
    }
    if x.width != y.width {
        return x.width, y.width, typeid_of(Tileset_Chunk), false
    }
    if x.height != y.height {
        return x.height, y.height, typeid_of(Tileset_Chunk), false
    }
    if x.base_index != y.base_index {
        return x.base_index, y.base_index, typeid_of(Tileset_Chunk), false
    }
    if x.name != x.name {
        return x.name, x.name, typeid_of(Tileset_Chunk), false
    }
    if x.external != y.external {
        return x.external, y.external, typeid_of(Tileset_External), false
    }
    if x.compressed == nil && y.compressed == nil {
        eq = true
        return
    } else if x.compressed != nil && y.compressed == nil {
        return "Tilemap Compressed X", nil, typeid_of(Tileset_Chunk), false
    } else if y.compressed != nil && x.compressed == nil {
        return nil, "Tilemap Compressed X", typeid_of(Tileset_Chunk), false
    }
    
    xc := x.compressed.(Tileset_Compressed)
    yc := y.compressed.(Tileset_Compressed)

    if !slice.equal(xc[:], yc[:]) {
        return xc, yc, typeid_of(Tileset_Compressed), false
    }

    eq = true
    return
}

_chunk_equal :: proc{
    _old_palette_256_equal, _old_plette_64_equal, _layer_equal, _cel_equal,
    _cel_extra_equal, _color_profile_equal, _external_files_equal, _mask_equal,
    _path_equal, _tags_equal, _palette_equal, _user_data_equal, _slice_equal,
    _tileset_equal,
}
