// Compile this as a separate program and run it to output a `file_version.odin` file
// that contains the filename and modification timestamp of all your textures. Compile
// `file_version.odin` as part of your game DLL.
//
// In your game code you can then compare the modification timestamp to the files
// to the one in `file_version.odin`. If they are different you can run `build_hot_reload.bat/sh`
// 
// This works nicely in combination with the Atlas Builder, making it possible to
// sit in Aseprite with the game running, modifying the source .ase files and having
// the game recomplile and output new atlases for you without having to leave aseprite.
//
// Example code of how to check the timetamps in `file_version.odin`:
// for f in file_versions {
// 	if mod, mod_err := os.last_write_time_by_name(f.path); mod_err == os.ERROR_NONE {
// 		if mod != f.modification_time {
// 			reload_error := libc.system("build_hot_reload.bat")
// 
// 			if reload_error == 0 {
// 				// successfully built game, hot reload will take care of rest
// 			}
// 		}
// 	}
// }

package file_version_builder

import "core:os"
import "core:fmt"
import "core:strings"

PACKAGE_NAME :: "game"
TEXTURES_DIR :: "textures"

dir_path_to_file_infos :: proc(path: string) -> []os.File_Info {
	d, derr := os.open(path, os.O_RDONLY)
	if derr != 0 {
		panic("open failed")
	}
	defer os.close(d)

	{
		file_info, ferr := os.fstat(d)
		defer os.file_info_delete(file_info)

		if ferr != 0 {
			panic("stat failed")
		}
		if !file_info.is_dir {
			panic("not a directory")
		}
	}

	file_infos, _ := os.read_dir(d, -1)
	return file_infos
}

main :: proc() {
	f, _ := os.open("file_version.odin", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	defer os.close(f)

	fmt.fprintfln(f, "package %v", PACKAGE_NAME)
	fmt.fprintln(f, "")
	fmt.fprintln(f, "import \"core:os\"")

	fmt.fprintln(f, "")
	fmt.fprintln(f, "FileVersion :: struct {")
	fmt.fprintln(f, "\tpath: string,")
	fmt.fprintln(f, "\tmodification_time: os.File_Time,")
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")
	fmt.fprintln(f, "file_versions := []FileVersion {")

	/*files_in_this_folder := dir_path_to_file_infos(".")
	for a in files_in_this_folder {
		if a.name == "atlas.odin" || a.name == "file_version.odin" {
			continue
		}

		if strings.has_suffix(a.name, ".odin") {
			mod, mod_err := os.last_write_time_by_name(a.fullpath)

			if mod_err != os.ERROR_NONE {
				continue
			}

			fmt.fprintf(f, "\t{{ path = %q, modification_time = %v }},\n", a.fullpath, mod)
		}
	}*/

	textures := dir_path_to_file_infos(TEXTURES_DIR)
	for a in textures {
		if strings.has_suffix(a.name, ".ase") || strings.has_suffix(a.name, ".aseprite") || strings.has_suffix(a.name, ".png") {
			mod, mod_err := os.last_write_time_by_name(a.fullpath)

			if mod_err != os.ERROR_NONE {
				continue
			}

			fmt.fprintf(f, "\t{{ path = %q, modification_time = %v }},\n", a.fullpath, mod)
		}
	}

	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")
}