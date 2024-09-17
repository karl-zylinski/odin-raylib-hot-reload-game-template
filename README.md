# Odin + Raylib + Hot Reload template

This is an Odin + Raylib game template with Hot Reloading pre-setup.

By Karl Zylinski, http://zylinski.se -- Support me at https://www.patreon.com/karl_zylinski

## Quick start

Here's how to get started with hot reloading gameplay code quickly.

Linux/macOS: Below, replace `.bat` with `.sh` and `.exe` with `.bin`.


1. Run `build_hot_reload.bat` to compile create `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
2. Run `game.exe`, leave it running. Note: On Windows you have to copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` into this directory.
3. Make changes to the gameplay code in `game/game.odin`. For example, change the line `rl.ClearBackground(rl.BLACK)` so that it instead uses `rl.BLUE`. Save the file.
4. Run `build_hot_reload.bat`, it will recompile `game.dll`.
5. `game.exe` will reload `game.dll` but use the same Game_Memory (a struct defined in `game/game.odin`) as before. This will make the game use your new code without having to restart.

Note, in step 4: `build_hot_reload.bat` does not rebuild `game.exe`. It check if `game.exe` is already running, and if it is, it avoid recompiling it, since it will be locked anyways.

## Description

This template is compatible with Windows, macOS and Linux. The instructions are mostly for Windows, but there is a [non-windows](#non-windows) section that explains the differences.

`build_hot_reload.bat` will build `game.dll` from the odin code in the `game` folder. It will also build `game.exe` from the code in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `Game_Memory` struct in `game/game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.dll`, instead it imports the `game` directory as a normal Odin package.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Sublime Text

There's sublime project called `project.sublime-project` in case you use Sublime Text. It comes with a build system, you should be able to open the project, select the build system (Main Menu -> Tools -> Build System -> Game template) and then compile + run the game by pressing F7/Ctrl+B/Cmd+B. Edit the project file to change the name of the build system.

## VS Code

Included there are Debug and Release tasks for VS Code. If you install the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension, it's possible to Debug the project code with the included Debug task.

A task to build and hot reload is also included, build, run and rebuild with `Ctrl+B` or `Command Palette` -> `Task: Run Build Task`.

## Extra files

In the folder `extras` you'll find some things that I often use in my games. Those files have comments at the top of each file that says what they do. It's just my personal "useful files" stash.

## Atlas builder

The `atlas_builder` subfolder contains a program that builds a texture atlas from separate aseprite and png files. You can look in `build_hot_reload.bat` for more info on how to enable it. The atlas builder outputs both an atlas PNG file as well as an `atlas.odin` file that contains metadata about where in the atlas the images are.

The atlas builder is meant to be run before the game DLL is compiled. Then, in your gameplay you can use `atlas_textures` in `atlas.odin` to know where in the atlas your textures ended up. Load the `atlas.png` using `rl.LoadTexture()` and then draw using it, something like:

```
atlas_rect := atlas_textures[.Some_Texture]
rl.DrawTextureRec(atlas_texture, atlas_rect, some_position, rl.WHITE)
```

For aseprite files with multiple frames animations will be outputted, which you find in the array `atlas_animations` of `atlas.odin`.

See `readme.md` in the `atlas_builder` folder for more info, there's also an example in that folder on how to use it.

## Demo streams

Streams that start from this template:
- CAR RACER prototype: https://www.youtube.com/watch?v=KVbHJ_CLdkA
- "point & click" prototype: https://www.youtube.com/watch?v=iRvs1Xr1W6o
- Metroidvania / platform prototype: https://www.youtube.com/watch?v=kIxEMchPc3Y
- Top-down adventure prototype: https://www.youtube.com/watch?v=cl8EOjOaoXc

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
