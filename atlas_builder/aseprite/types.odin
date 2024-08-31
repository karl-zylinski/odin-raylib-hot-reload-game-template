package aseprite_file_handler


import "base:runtime"
import "core:io"
import "core:math/fixed"
import "core:compress/zlib"
import vzlib "vendor:zlib"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

// TODO: Whole File rework.
// Anything set by a flag should be a Maybe(). 
// Only Size/Lengths that can't be gotten by len() are set.

Unmarshal_Errors :: enum {
    Unable_To_Open_File,
    Unable_Make_Reader,
    Bad_File_Magic_Number,
    Bad_Frame_Magic_Number,
    Bad_User_Data_Type,
    Data_Size_Not_Equal_To_Header,
    Invalid_Chunk_Type,
    Invalid_Cel_Type,
    Invalid_Compression_Size,

    User_Data_Maps_Not_Supported,
}
Unmarshal_Error :: union #shared_nil {
    Unmarshal_Errors, 
    runtime.Allocator_Error, 
    io.Error,
    Read_Error,
    zlib.Error,
    ZLIB_Errors,
}

Read_Errors :: enum {
    Unable_To_Decode_Data,
    Wrong_Read_Size,
    Array_To_Small,
    Unable_Make_Seeker,
}
Read_Error :: union #shared_nil {Read_Errors, io.Error, runtime.Allocator_Error}

Marshal_Errors :: enum {
    Unable_Make_Writer,
    Buffer_Not_Big_Enough,
    Invalid_Chunk_Type,
    Wrong_Write_Size,
    Invalid_Old_Palette,
    Invalid_Cel_Type,
    Invalid_Property_Type,
}
Marshal_Error :: union #shared_nil {
    Marshal_Errors, 
    runtime.Allocator_Error, 
    Write_Error,
    io.Error,
    ZLIB_Errors,
}

Write_Errors :: enum {
    Unable_To_Encode_Data,
    Wrong_Write_Size,
    Array_To_Small,
    Unable_Make_Seeker,
}
Write_Error :: union #shared_nil {
    Write_Errors, 
    io.Error, 
    runtime.Allocator_Error,
}

ZLIB_Errors :: enum(i32) {
    ERRNO = vzlib.ERRNO,
    STREAM_ERROR = vzlib.STREAM_ERROR,
    DATA_ERROR = vzlib.DATA_ERROR,
    MEM_ERROR = vzlib.MEM_ERROR,
    BUF_ERROR = vzlib.BUF_ERROR,
    VERSION_ERROR = vzlib.VERSION_ERROR,
}

// all writen in le
BYTE   :: u8
WORD   :: u16
SHORT  :: i16
DWORD  :: u32
LONG   :: i32
FIXED  :: fixed.Fixed16_16
FLOAT  :: f32
DOUBLE :: f64
QWORD  :: u64
LONG64 :: i64

BYTE_N :: [dynamic]BYTE

// https://odin-lang.org/docs/overview/#packed
STRING :: string
POINT :: struct {
    x: LONG,
    y: LONG,
}
SIZE :: struct {
    w: LONG,
    h: LONG,
}
RECT :: struct {
    origin: POINT,
    size: SIZE,
}

PIXEL_RGBA      :: [4]BYTE
PIXEL_GRAYSCALE :: [2]BYTE
PIXEL_INDEXED   :: BYTE

// PIXEL :: union {PIXEL_RGBA, PIXEL_GRAYSCALE, PIXEL_INDEXED}
PIXEL :: u8
TILE  :: union {BYTE, WORD, DWORD}

// of size 16
UUID :: distinct []BYTE

Color_RGB :: [3]BYTE
Color_RGBA :: [4]BYTE

Document :: struct {
    header: File_Header,
    frames: []Frame,
}

Frame :: struct {
    header: Frame_Header,
    chunks: []Chunk,
}

Chunk :: union{
    Old_Palette_256_Chunk, Old_Palette_64_Chunk, Layer_Chunk, Cel_Chunk, 
    Cel_Extra_Chunk, Color_Profile_Chunk, External_Files_Chunk, Mask_Chunk, 
    Path_Chunk, Tags_Chunk, Palette_Chunk, User_Data_Chunk, Slice_Chunk, 
    Tileset_Chunk,
}

FILE_MAGIC_NUM : WORD : 0xA5E0
FILE_HEADER_SIZE :: 128

Color_Depth :: enum(WORD){
    Indexed=8,
    Grayscale=16,
    RGBA=32,
}
File_Flag :: enum(DWORD){
    Layer_Opacity,
}
File_Flags :: bit_set[File_Flag; DWORD]
File_Header :: struct {
    size: DWORD,
    frames: WORD,
    width: WORD,
    height: WORD,
    color_depth: Color_Depth,
    flags: File_Flags, // 1=Layer opacity has valid value
    speed: WORD, // Not longer in use
    transparent_index: BYTE, // for Indexed sprites only
    num_of_colors: WORD, // 0 == 256 for old sprites
    ratio_width: BYTE, // "pixel width/pixel height" if 0 ratio == 1:1
    ratio_height: BYTE, // "pixel width/pixel height" if 0 ratio == 1:1
    x: SHORT,
    y: SHORT,
    grid_width: WORD, // 0 if no grid
    grid_height: WORD, // 0 if no grid
}

FRAME_HEADER_SIZE :: 16
FRAME_MAGIC_NUM : WORD : 0xF1FA
Frame_Header :: struct {
    old_num_of_chunks: WORD, // if \xFFFF use new
    duration: WORD, // in milliseconds
    num_of_chunks: DWORD, // if 0 use old
}

Chunk_Types :: enum(WORD) {
    none,
    old_palette_256 = 0x0004,
    old_palette_64 = 0x0011,
    layer = 0x2004,
    cel = 0x2005,
    cel_extra = 0x2006,
    color_profile = 0x2007,
    external_files = 0x2008,
    mask = 0x2016, // no longer in use
    path = 0x2017, // not in use
    tags = 0x2018,
    palette = 0x2019,
    user_data = 0x2020,
    slice = 0x2022,
    tileset = 0x2023,
}

Chunk_Types_Set :: enum {
    old_palette_256,
    old_palette_64,
    layer,
    cel,
    cel_extra,
    color_profile,
    external_files,
    mask, // no longer in use
    path, // not in use
    tags,
    palette,
    user_data,
    slice,
    tileset,
}
Chunk_Set :: bit_set[Chunk_Types_Set]


Old_Palette_Packet :: struct {
    entries_to_skip: BYTE, // start from 0
    num_colors: BYTE, // 0 == 256
    colors: []Color_RGB,
}
Old_Palette_256_Chunk :: distinct []Old_Palette_Packet
Old_Palette_64_Chunk :: distinct []Old_Palette_Packet
// Old_Palette_256_Chunk :: struct{packets: []Old_Palette_Packet}
// Old_Palette_64_Chunk :: struct{packets: []Old_Palette_Packet}

Layer_Chunk_Flag :: enum(WORD) {
    Visiable,
    Editable,
    Lock_Movement,
    Background,
    Prefer_Linked_Cels,
    Group_Collapsed,
    Ref_Layer,
}
Layer_Chunk_Flags :: bit_set [Layer_Chunk_Flag; WORD]
Layer_Types :: enum(WORD) {
    Normal, // image
    Group,
    Tilemap,
}
Layer_Blend_Mode :: enum(WORD) {
    Normal,
    Multiply,
    Screen,
    Overlay,
    Darken,
    Lighten,
    Color_Dodge,
    Color_Burn,
    Hard_Light,
    Soft_Light,
    Difference,
    Exclusion,
    Hue,
    Saturation,
    Color,
    Luminosity,
    Addition,
    Subtract,
    Divide,
}
Layer_Chunk :: struct {
    flags: Layer_Chunk_Flags,
    type: Layer_Types,
    child_level: WORD,
    default_width: WORD, // Ignored
    default_height: WORD, // Ignored
    blend_mode: Layer_Blend_Mode,
    opacity: BYTE, // valid when header flag is 1
    name: string,
    tileset_index: DWORD, // set if type == Tilemap
}


Raw_Cel :: struct{
    width: WORD, 
    height: WORD, 
    pixel: []PIXEL,
}
Linked_Cel :: distinct WORD
// raw cel ZLIB compressed
Com_Image_Cel :: struct{
    width: WORD, 
    height: WORD, 
    pixel: []PIXEL,
}
Tile_ID :: enum(DWORD) { byte=0xfffffff1, word=0xffff1fff, dword=0x1fffffff }
Com_Tilemap_Cel :: struct{
    width, height: WORD,
    bits_per_tile: WORD, // always 32
    bitmask_id: Tile_ID,
    bitmask_x: DWORD,
    bitmask_y: DWORD,
    bitmask_diagonal: DWORD,
    tiles: []TILE, // ZLIB compressed
}
Cel_Types :: enum(WORD){
    Raw,
    Linked_Cel,
    Compressed_Image,
    Compressed_Tilemap,
}
Cel_Type :: union{ Raw_Cel, Linked_Cel, Com_Image_Cel, Com_Tilemap_Cel}
Cel_Chunk :: struct {
    layer_index: WORD,
    x,y: SHORT,
    opacity_level: BYTE,
    type: Cel_Types,
    z_index: SHORT, //0=default, pos=show n layers later, neg=back
    cel: Cel_Type,
}


Cel_Extra_Flag :: enum(WORD){Precise}
Cel_Extra_Flags :: bit_set[Cel_Extra_Flag; WORD]
Cel_Extra_Chunk :: struct {
    flags: Cel_Extra_Flags,
    x: FIXED,
    y: FIXED,
    width: FIXED, 
    height: FIXED,
}


ICC_Profile :: distinct []byte
Color_Profile_Flag :: enum(WORD){Special_Fixed_Gamma}
Color_Profile_Flags :: bit_set[Color_Profile_Flag; WORD]
Color_Profile_Type :: enum(WORD) {
    None,
    sRGB,
    ICC,
}
Color_Profile_Chunk :: struct {
    type: Color_Profile_Type,
    flags: Color_Profile_Flags,
    fixed_gamma: FIXED,
    // TODO: Yay more libs to make, https://www.color.org/icc1v42.pdf
    icc: Maybe(ICC_Profile),
}


ExF_Entry_Type :: enum(BYTE){
    Palette,
    Tileset,
    Properties_Name,
    Tile_Manegment_Name,
}
External_Files_Entry :: struct{
    id: DWORD,
    type: ExF_Entry_Type,
    file_name_or_id: STRING,
}
External_Files_Chunk :: []External_Files_Entry


Mask_Chunk :: struct {
    x,y: SHORT,
    width, height: WORD,
    name: string,
    bit_map_data: []BYTE, //size = height*((width+7)/8)
}


Path_Chunk :: struct{} // never used


Tag_Loop_Dir :: enum(BYTE){
    Forward,
    Reverse,
    Ping_Pong,
    Ping_Pong_Reverse,
}
Tag :: struct{
    from_frame: WORD,
    to_frame: WORD,
    loop_direction: Tag_Loop_Dir,
    repeat: WORD,
    tag_color: Color_RGB,
    name: string,
}
Tags_Chunk :: []Tag


Pal_Flag :: enum(WORD){Has_Name}
Pal_Flags :: bit_set[Pal_Flag; WORD]
Palette_Entry :: struct {
    color: Color_RGBA,
    name: Maybe(string),
}
Palette_Chunk :: struct {
    size: DWORD,
    first_index: DWORD,
    last_index: DWORD,
    entries: []Palette_Entry,
}


// Vec_Diff :: struct{type: WORD, data: UD_Property_Value}
// UD_Vec :: union {[]UD_Property_Value, []Vec_Diff}
UD_Vec :: []Property_Value
Property_Type :: enum(WORD) {
    Null, Bool, I8, U8, I16, U16, I32, U32, I64, U64,
    Fixed, F32, F64, String, Point, Size, Rect, 
    Vector, Properties, UUID, 
}
Property_Value :: union {
    bool, i8, BYTE, SHORT, WORD, LONG, DWORD, LONG64, QWORD, FIXED, FLOAT,
    DOUBLE, STRING, POINT, SIZE, RECT, UUID,  
    UD_Vec, Properties, 
}
Properties :: map[string]Property_Value
Properties_Map :: map[DWORD]Property_Value
UD_Flag :: enum(DWORD) {
    Text,
    Color,
    Properties,
}
UD_Flags :: bit_set[UD_Flag; DWORD]
User_Data_Chunk :: struct {
    text: Maybe(string), 
    color: Maybe(Color_RGBA), 
    maps: Maybe(Properties_Map),

}


Slice_Center :: struct{
    x: LONG,
    y: LONG, 
    width: DWORD, 
    height: DWORD,
}
Slice_Pivot :: distinct POINT
Slice_Key :: struct{
    frame_num: DWORD,
    x: LONG,
    y: LONG, 
    width: DWORD, 
    height: DWORD,
    center: Maybe(Slice_Center),
    pivot: Maybe(Slice_Pivot),
}
Slice_Flag :: enum(DWORD) {
    Patched_slice, 
    Pivot_Information,
}
Slice_Flags :: bit_set[Slice_Flag; DWORD]
Slice_Chunk :: struct {
    flags: Slice_Flags,
    name: string,
    keys: []Slice_Key,
}


Tileset_Flag :: enum(DWORD) {
    Include_Link_To_External_File,
    Include_Tiles_Inside_This_File,
    Tile_ID_Is_0,
    Auto_Mode_X_Flip_Match,
    Auto_Mode_Y_Flip_Match,
    Auto_Mode_Diagonal_Flip_Match,
}
Tileset_Flags :: bit_set[Tileset_Flag; DWORD]
Tileset_External :: struct{
    file_id, tileset_id: DWORD,
}
Tileset_Compressed :: distinct []PIXEL
Tileset_Chunk :: struct {
    id: DWORD,
    flags: Tileset_Flags,
    num_of_tiles: DWORD,
    width: WORD, 
    height: WORD,
    base_index: SHORT,
    name: string,
    external: Maybe(Tileset_External), 
    compressed: Maybe(Tileset_Compressed),
}
