## Description

This is a small game template for Odin + Raylib with hot reloading pre-setup. It contains stuff that my different game projects had in common, so I made this template so I can get up and running quicker.

`build_dev.bat` will build `game.dll` from the stuff in this directory. It will also build `game.exe` from the stuff in the directory `main_hot_reload`. When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything that is compiled as part of `game.dll` and re-run `build_dev.bat`. `game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `GameMemory` struct in `game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game.

There are also some additional files with some helpers that I find useful.

## Setup

- Edit `build_dev_main.bat` so it uses the correct path to copy `raylib.dll` from.
- Run `build_dev.bat` to compile `game.exe` and `game.dll`
- Run `game.exe`
- Make changes to the gameplay code
- Run `build_dev.bat` again while game.exe is running, it will recompile game.dll
- `game.exe` will reload `game.dll` but use the same GameMemory (a struct defined in `game.odin`) as before.

## Sublime
There's a `project.sublime-project` in case you use sublime. Edit it and make sure the paths to the folders within the Odin compiler directory are correct. I put those as part of my project so I can quickly jump to symbols within core & raylib. Also make sure the working directory of the build system in there is correct, in case you want to use the included build system.

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
