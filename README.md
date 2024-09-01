# Odin + Raylib + Hot Reload template (+ Atlas Builder!) -- This branch: Atlas & atlased animation example!
By Karl Zylinski, http://zylinski.se -- Support me at https://www.patreon.com/karl_zylinski

## Extra description about this branch

This branch shows how to use the atlas builder and also how to do atlased animations. It also uses an atlased font and the raylib shapes (rl.DrawRectangleRec etc) use the atlas as well. There are lots of comments in `game/game.odin` that explains how it works.

Overview of what happens:
- `build_hot_reload` / `build_release` script runs atlas builder, which outputs `atlas.png` and `game/atlas.odin`.
- `game/atlas.odin` contains info about where in `atlas.png` the textures in the `textures` folder ended up, including animations (aseprite textures that had more than one frame... It also supports tags for multiple animations within a single aseprite file)
- `game/atlas.odin` also contains info about where in `atlas.png` letters from the font `font.ttf` ended up
- It compiles the game. `game/atlas.odin` will be compiled as part of the game. You thus reason about texture and animation names at compile-time.
- when `game.odin` compiles it loads the `atlas.png` into a compile-time-array of bytes, stored in `ATLAS_DATA` constant. This means your executable won't need `atlas.png`, it's inside the executable / game DLL.
- when the game starts it loads a raylib texture from `ATLAS_DATA`
- It uses the stuff in `game/animation.odin` to setup, update and draw an animation for the player, based on the animation `textures/player.ase` (which is accessible in `game/atlas.odin` under the enum value `Animation_Name.Player`)
- It also draws text using a font that lives in the atlas. This font is reconstructed into a raylib font. See `load_atlased_font` in `game/game.odin`
- It also draws raylib shapes (rl.DrawRectangleRec etc) using a shapes-drawing-texture that lives in the atlas. See `rl.SetShapesTexture(atlas, shapes_texture_rect)` line in `game/game.odin`.

The game will look like this, and at the bottom you see a capture in RenderDoc that shows hows how everything is done using 2 draw calls. One for the game and one for the UI.
![image](https://github.com/user-attachments/assets/d0c0ac59-4180-4bc0-90cf-f11d6db142f0)

## Description

This is an Odin + Raylib game template with Hot Reloading pre-setup. My game projects tend to have some things in common, so I made this template so I can get up and running quickly.

This template is compatible with Windows, macOS and Linux. The instructions are mostly for Windows, but there is a [non-windows](#non-windows) section that explains the differences.

`build_hot_reload.bat` will build `game.dll` from the odin code in the `game` folder. It will also build `game.exe` from the code in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `Game_Memory` struct in `game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.dll`, instead it imports the `game` directory as a normal Odin package.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Setup and usage

- Copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` to the root of this repo.
- Run `build_hot_reload.bat` to compile `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
- Run `game.exe`
- Make changes to the gameplay code (for example, make changes in the proc `update` or `draw` in `game/game.odin`)
- Run `build_hot_reload.bat` again while game.exe is running, it will recompile `game.dll`
- `game.exe` will reload `game.dll` but use the same Game_Memory (a struct defined in `game/game.odin`) as before.

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

See `readme.md` in the `atlas_builder` folder for more info and the branch [atlas-animation-example](https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/tree/atlas-animation-example) for an example on how to use the atlas builder in practice.

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

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
