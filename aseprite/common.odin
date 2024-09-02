package aseprite_file_handler

import "core:fmt"
import "core:log"
_ :: fmt
_ :: log

@(private)
destroy_value :: proc(p: ^Property_Value, alloc := context.allocator) {
    context.allocator = alloc
    #partial switch &val in p {
    case string:
        // FIXME: Strings fail to free sometimes.
        delete(val)
    case UD_Vec:
        for &v in val {
            destroy_value(&v)
        }
        delete(val)

    case Properties:
        for _, &v in val {
            destroy_value(&v)
        }
        delete(val)
    }
}

destroy_doc :: proc(doc: ^Document, alloc := context.allocator) {
    context.allocator = alloc
    for &frame in doc.frames {
        for &chunk in frame.chunks {
            #partial switch &v in chunk {
            case Old_Palette_256_Chunk:
                for pack in v {
                    delete(pack.colors)
                }
                delete(v)

            case Old_Palette_64_Chunk:
                for pack in v {
                    delete(pack.colors)
                }
                delete(v)
            case Layer_Chunk:
                delete(v.name)

            case Cel_Chunk:
                switch &cel in v.cel {
                case Linked_Cel:
                case Raw_Cel:
                    delete(cel.pixel)
                case Com_Image_Cel:
                    delete(cel.pixel)
                case Com_Tilemap_Cel:
                    delete(cel.tiles)
                }

            case Color_Profile_Chunk:
                switch icc in v.icc {
                case ICC_Profile:
                    delete(icc)
                }

            case External_Files_Chunk:
                for &e in v {
                    delete(e.file_name_or_id)
                }
                delete(v)
                
            case Mask_Chunk:
                delete(v.name)
                delete(v.bit_map_data)

            case Tags_Chunk:
                for &t in v {
                    delete(t.name)
                }
                delete(v)

            case Palette_Chunk:
                for &e in v.entries {
                    switch &s in e.name {
                    case string:
                        delete(s)
                    }
                }
                delete(v.entries)

            case User_Data_Chunk:
                switch &s in v.text {
                case string:
                    delete(s)
                }

                switch &m in v.maps {
                case Properties_Map:
                    for _, &val in m {
                        destroy_value(&val)
                    }
                    delete_map(m)
                }

            case Slice_Chunk:
                delete(v.name)
                delete(v.keys)

            case Tileset_Chunk:
                delete(v.name)
                switch &c in v.compressed {
                case Tileset_Compressed:
                    delete(c)
                }
            }
        }
        delete(frame.chunks)
    }
    delete(doc.frames)
}

destroy_chunk :: proc {
    _destroy_old_256, _destroy_old_64, _destroy_layer, _destroy_cel, 
    _destroy_cel_extra, _destroy_color_profile, _destroy_external_files,
    _destroy_mask, _destroy_path, _destroy_tags, _destroy_palette,
    _destroy_user_data, _destroy_slice, _destroy_tileset,
}

@(private)
_destroy_old_256 :: proc(c: Old_Palette_256_Chunk) {
    for pack in c {
        delete(pack.colors)
    }
    delete(c)
}

@(private)
_destroy_old_64 :: proc(c: Old_Palette_64_Chunk) {
    for pack in c {
        delete(pack.colors)
    }
    delete(c)
}

@(private)
_destroy_layer :: proc(c: Layer_Chunk) {
    delete(c.name)
}

@(private)
_destroy_cel :: proc(c: Cel_Chunk) {
    switch cel in c.cel {
    case Linked_Cel:
    case Raw_Cel:
        delete(cel.pixel)
    case Com_Image_Cel:
        delete(cel.pixel)
    case Com_Tilemap_Cel:
        delete(cel.tiles)
    }
}

@(private)
_destroy_cel_extra :: proc(c: Cel_Extra_Chunk) {}

@(private)
_destroy_color_profile :: proc(c: Color_Profile_Chunk) {
    switch icc in c.icc {
    case ICC_Profile:
        delete(icc)
    }
}

@(private)
_destroy_external_files :: proc(c: External_Files_Chunk) {
    for e in c {
        delete(e.file_name_or_id)
    }
    delete(c)
}

@(private)
_destroy_mask :: proc(c: Mask_Chunk) {
    delete(c.name)
    delete(c.bit_map_data)
}

@(private)
_destroy_path :: proc(c: Path_Chunk) {}

@(private)
_destroy_tags :: proc(c: Tags_Chunk) {
    for t in c {
        delete(t.name)
    }
    delete(c)
}

@(private)
_destroy_palette :: proc(c: Palette_Chunk) {
    for e in c.entries {
        switch s in e.name {
        case string: delete(s)
        }
    }
    delete(c.entries)
}

@(private)
_destroy_user_data :: proc(c: User_Data_Chunk) {
    switch &s in c.text {
    case string:
        delete(s)
    }

    switch &m in c.maps {
    case Properties_Map:
        for _, &val in m {
            destroy_value(&val)
        }
        delete_map(m)
    }
}

@(private)
_destroy_slice :: proc(c: Slice_Chunk) {
    delete(c.name)
    delete(c.keys)
}

@(private)
_destroy_tileset :: proc(c: Tileset_Chunk) {
    delete(c.name)
    switch v in c.compressed {
    case Tileset_Compressed:
        delete(v)
    }
}
