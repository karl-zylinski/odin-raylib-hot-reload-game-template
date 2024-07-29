package aseprite_file_handler

import "core:fmt"

destroy_doc :: proc(doc: ^Document) {
    destroy_value :: proc(p: ^Property_Value) {
        #partial switch &val in p {
        case STRING:
            delete(val)
        case UD_Vec:
            for &v in val {
                destroy_value(&v)
            }
            delete(val)

        case Properties:
            for k, &v in val {
                destroy_value(&v)
            }
            delete(val)
        }
    }

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
                    // FIXME: Fails to free.
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

                if m, ok := v.maps.?; ok {
                    for k, &val in m {
                        destroy_value(&val)
                    }
                    delete_map(m)
                }
                /*// FIXME: Fails to free.
                switch &m in v.maps {
                case Properties_Map:
                    for k, &val in m {
                        destroy_value(&val)
                    }
                    delete_map(m)
                }*/

            case Slice_Chunk:
                delete(v.name)
                delete(v.keys)

            case Tileset_Chunk:
                delete(v.name)
                // FIXME: Fails to free.
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