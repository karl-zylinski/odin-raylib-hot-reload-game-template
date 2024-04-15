## Description

This is an Odin + Raylib game template with Hot Reloading pre-setup.  My game projects tend to have some things in common, so I made this template so I can get up and running quicker. 

`build_hot_reload.bat` will build `game.dll` from the stuff in the root directory of this repository. It will also build `game.exe` from the stuff in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_hot_reload.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `GameMemory` struct in `game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game.

There are also some additional files with some helpers that I find useful. See [Optional files](#optional-files) below.

## Setup and usage

- Copy `raylib.dll` from `your_odin_compiler/vendor/raylib/windows` to the root of this repo.
- Run `build_hot_reload.bat` to compile `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
- Run `game.exe`
- Make changes to the gameplay code (for example, make changes in the proc `update` or `draw` in `game.odin`)
- Run `build_hot_reload.bat` again while game.exe is running, it will recompile `game.dll`
- `game.exe` will reload `game.dll` but use the same GameMemory (a struct defined in `game.odin`) as before.

## Sublime Text
There's a `project.sublime-project` in case you use Sublime Text. Edit it and make sure the paths to the folders within the Odin compiler directory are correct. I put those as part of my project so I can quickly jump to symbols within core & raylib.

## VS Code
Included there are Debug and Release tasks for VS Code. If you install the [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension, it's possible to Debug the project code with the included Debug task.

A task to build and hot reload is also included, build, run and rebuild with `Ctrl+B` or `Command Palette` -> `Task: Run Build Task`.

## Optional files
Only `game.odin` and `math.odin` are required to compile the game DLL. You can delete the other files in the root directrory of the repo if you wish. They are there because they contain things I often use in all projects. Most of them have a description at the top of the file, explaining what it contains.

## Demo video
I did a stream where I prototype a game by starting from scratch with this template. You can watch it here: https://www.youtube.com/watch?v=cl8EOjOaoXc It is very long, but it's mostly the front part that is interesting with regards to how to use this template.

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
