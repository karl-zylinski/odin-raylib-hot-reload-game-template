## Description

This is an Odin + Raylib game template with Hot Reloading pre-setup. My game projects tend to have some things in common, so I made this template so I can get up and running quickly.

This template is compatible with Windows, macOS and Linux. The instructions are mostly for Windows, but there is a [non-windows](#non-windows) section that explains the differences.

`build_hot_reload.bat` will build `game.dll` from the odin code in the root of the repository. It will also build `game.exe` from the code in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `Game_Memory` struct in `game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Setup and usage

- Copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` to the root of this repo.
- Run `build_hot_reload.bat` to compile `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
- Run `game.exe`
- Make changes to the gameplay code (for example, make changes in the proc `update` or `draw` in `game.odin`)
- Run `build_hot_reload.bat` again while game.exe is running, it will recompile `game.dll`
- `game.exe` will reload `game.dll` but use the same Game_Memory (a struct defined in `game.odin`) as before.

### Non-Windows

The template also supports Linux and MacOS, all mentions of `.bat` scripts have an equivalent `.sh` script, and the game is built as `game.bin` instead of `game.exe`.

Unlike Windows, there is no need to copy any Raylib library to the root of this repo.

## Sublime Text

There's sublime project called `project.sublime-project` in case you use Sublime Text. It comes with a build system, you should be able to open the project, select the build system (Main Menu -> Tools -> Build System -> Game template) and then compile + run the game by pressing F7/Ctrl+B/Cmd+B. Edit the project file to change the name of the build system.

## VS Code

Included there are Debug and Release tasks for VS Code. If you install the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension, it's possible to Debug the project code with the included Debug task.

A task to build and hot reload is also included, build, run and rebuild with `Ctrl+B` or `Command Palette` -> `Task: Run Build Task`.

## Optional files

Only `game.odin` and `math.odin` are required to compile the game DLL. You can delete the other `.odin` files in the root directrory of the repository if you wish. They are there because they contain things I often use in all projects. Most of them have a description at the top of the file, explaining what it contains.

## Atlas builder

The `atlas_builder` subfolder contains a program that builds a texture atlas from separate aseprite and png files. You can look in `build_hot_reload.bat` for more info on how to enable it. The atlas builder outputs both an atlas PNG file as well as an `atlas.odin` file that contains metadata about where in the atlas the images are.

The atlas builder is meant to be run before the game DLL is compiled. Then, in your gameplay you can use `atlas_textures` in `atlas.odin` to know where in the atlas your textures ended up. Load the `atlas.png` using `rl.LoadTexture()` and then draw using it, something like:

```
atlas_rect := atlas_textures[.Some_Texture]
rl.DrawTextureRec(atlas_texture, atlas_rect, some_position, rl.WHITE)
```

For aseprite files with multiple frames animations will be outputted, which you find in the array `atlas_animations` of `atlas.odin`.

## Demo streams

Streams that start from this template:
- CAR RACER prototype: https://www.youtube.com/watch?v=KVbHJ_CLdkA
- "point & click" prototype: https://www.youtube.com/watch?v=iRvs1Xr1W6o
- Metroidvania / platform prototype: https://www.youtube.com/watch?v=kIxEMchPc3Y
- Top-down adventure prototype: https://www.youtube.com/watch?v=cl8EOjOaoXc

## Projects based on this template

| Name | Type | Description |
| ---- | ---- | ----------- |
| [Subfolders](https://github.com/alfredbaudisch/odin-raylib-hot-reload-game-template/tree/build-subfolders) | Extended Template | Adds sub folders for built binaries and the game DLL's source code |

Got a project based on this template? I'd gladly have it on this list! It can be a game based on the template or an extension/spinoff of the template. Just send me a link on [Discord](https://discord.gg/4FsHgtBmFK) or on karl@zylinski.se, or PR the entry into this README 😻 

## Support me on Patreon
https://www.patreon.com/karl_zylinski

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
