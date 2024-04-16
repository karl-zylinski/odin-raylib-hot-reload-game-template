## Description

This is an Odin + Raylib game template with Hot Reloading pre-setup. My game projects tend to have some things in common, so I made this template so I can get up and running quicker.

This template is compatible with Windows, macOS and Linux. The instructions are mostly for windows, but there is a [non-windows](#non-windows) section that explains the differences.

`build_hot_reload.bat` will build `game.dll` from the odin code in the root of the repository. It will also build `game.exe` from the code in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `GameMemory` struct in `game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Setup and usage

- Copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` to the root of this repo.
- Run `build_hot_reload.bat` to compile `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
- Run `game.exe`
- Make changes to the gameplay code (for example, make changes in the proc `update` or `draw` in `game.odin`)
- Run `build_hot_reload.bat` again while game.exe is running, it will recompile `game.dll`
- `game.exe` will reload `game.dll` but use the same GameMemory (a struct defined in `game.odin`) as before.

### Non-Windows

The template also supports Linux and MacOS, all mentions of `.bat` scripts have an equivalent `.sh` script, and the game is built as `game.bin` instead of `game.exe`.

Unlike Windows, there is no need to copy any Raylib library to the root of this repo.

#### Important note on Linux

The Raylib bindings are currently a bit broken regarding shared libraries, there is this PR that is trying to fix it: https://github.com/odin-lang/Odin/pull/3369.

So this will work nicely out of the box when that is corrected & merged, what you should be able to do at the moment as a workaround is go into the `vendor/raylib/raylib.odin` file and change the `"linux/libraylib.so.500"` to `"linux/libraylib.so"`.

## Sublime Text

There's sublime project called `project.sublime-project` in case you use Sublime Text. It comes with a build system, you should be able to open the project, select the build system (Main Menu -> Tools -> Build System -> Game template) and then compile + run the game by pressing F7/Ctrl+B/Cmd+B. Edit the project file to change the name of the build system.

## VS Code

Included there are Debug and Release tasks for VS Code. If you install the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension, it's possible to Debug the project code with the included Debug task.

A task to build and hot reload is also included, build, run and rebuild with `Ctrl+B` or `Command Palette` -> `Task: Run Build Task`.

## Optional files

Only `game.odin` and `math.odin` are required to compile the game DLL. You can delete the other files in the root directrory of the repository if you wish. They are there because they contain things I often use in all projects. Most of them have a description at the top of the file, explaining what it contains.

## Demo video

I did a stream where I prototype a game by starting from scratch with this template. You can watch it here: https://www.youtube.com/watch?v=cl8EOjOaoXc It is very long, but it's mostly the front part that is interesting with regards to how to use this template.

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
