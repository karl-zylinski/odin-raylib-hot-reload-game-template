# Odin + Raylib + Hot Reload template

This is an Odin + Raylib game template with Hot Reloading pre-setup. It makes it possible to reload gameplay code while the game is running.

Supported platforms: Windows, macOS and Linux.

![hot_reload gif](https://github.com/user-attachments/assets/18059ab2-0878-4617-971d-e629a969fc93)

I used this kind of hot reloading while developing my game [CAT & ONION](https://store.steampowered.com/app/2781210/CAT__ONION/).

By Karl Zylinski, http://zylinski.se -- Support me at https://www.patreon.com/karl_zylinski

## Quick start

If you are on Linux / macOS: Below, replace `.bat` with `.sh` and `.exe` with `.bin`.

1. Run `build_hot_reload.bat` to create `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
2. Run `game.exe`, leave it running. Note: On Windows you have to copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` into this directory.
3. Make changes to the gameplay code in `game/game.odin`. For example, change the line `rl.ClearBackground(rl.BLACK)` so that it instead uses `rl.BLUE`. Save the file.
4. Run `build_hot_reload.bat`, it will recompile `game.dll`.
5. The running `game.exe` will see that `game.dll` changed and reload it. But it will use the same `Game_Memory` (a struct defined in `game/game.odin`) as before. This will make the game use your new code without having to restart.

Note, in step 4: `build_hot_reload.bat` does not rebuild `game.exe`. It checks if `game.exe` is already running, and if it is, it avoid recompiling it, since it will be locked anyways.

## Description

`build_hot_reload.bat` will build `game.dll` from the odin code in the `game` folder. It will also build `game.exe` from the code in the directory `main_hot_reload`.

When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`.

`game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `Game_Memory` struct in `game/game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.dll`, instead it imports the `game` directory as a normal Odin package.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Sublime Text

In case you use Sublime Text, there's a project pre-setup `project.sublime-project`. It comes with a build system, you should be able to open the project, select the build system (Main Menu -> Tools -> Build System -> Game template) and then compile + run the game by pressing F7/Ctrl+B/Cmd+B. Edit the project file to change the name of the build system.

## VS Code

Included there are Debug and Release tasks for VS Code. If you install the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension, it's possible to Debug the project code with the included Debug task.

A task to build and hot reload is also included, build, run and rebuild with `Ctrl+B` or `Command Palette` -> `Task: Run Build Task`.

## Extra files

In the folder `extras` you'll find some things that I often use in my games. Those files have comments at the top of each file that says what they do. It's just my personal "useful files" stash.

## Atlas builder

This code works nicely together with my [atlas builder](https://github.com/karl-zylinski/atlas-builder). The atlas builder can build an atlas texture from a folder of png or aseprite files. Using an atlas can drastically reduce the number of draw calls your game uses. There's an example in that repository on how to set it up. The atlas generation step can easily be integrated into the build `bat` / `sh` files such as `build_hot_reload.bat`

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
