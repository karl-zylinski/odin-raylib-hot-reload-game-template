package aseprite_file_handler

import "base:runtime"
import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:slice"
import "core:unicode/utf8"
import "core:encoding/endian"

// https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
// https://github.com/alpine-alpaca/asefile
// https://github.com/AristurtleDev/AsepriteDotNet/blob/main/source/AsepriteDotNet/Document/UserData.cs
