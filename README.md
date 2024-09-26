# Odin + Raylib + Hot Reload template

This is an [Odin](https://github.com/odin-lang/Odin) + [Raylib](https://github.com/raysan5/raylib) game template with [Hot Reloading](http://zylinski.se/posts/hot-reload-gameplay-code/) pre-setup. It makes it possible to reload gameplay code while the game is running.

Supported platforms: Windows, macOS and Linux.

![hot_reload gif](https://github.com/user-attachments/assets/18059ab2-0878-4617-971d-e629a969fc93)

I used this kind of hot reloading while developing my game [CAT & ONION](https://store.steampowered.com/app/2781210/CAT__ONION/).

## Quick start

If you are on Linux / macOS: Below, replace `.bat` with `.sh` and `.exe` with `.bin`.

1. Run `build_hot_reload.bat` to create `game.exe` and `game.dll`. Note: It expects odin compiler to be part of your PATH environment variable.
2. Run `game.exe`, leave it running.
3. Make changes to the gameplay code in `game/game.odin`. For example, change the line `rl.ClearBackground(rl.BLACK)` so that it instead uses `rl.BLUE`. Save the file.
4. Run `build_hot_reload.bat`, it will recompile `game.dll`.
5. The running `game.exe` will see that `game.dll` changed and reload it. But it will use the same `Game_Memory` (a struct defined in `game/game.odin`) as before. This will make the game use your new code without having to restart.

Note, in step 4: `build_hot_reload.bat` does not rebuild `game.exe`. It checks if `game.exe` is already running, and if it is, it avoid recompiling it, since it will be locked anyways.

## Description

`build_hot_reload.bat` will build `game.dll` from the odin code in the `game` folder. It will also build `game.exe` from the code in the folder `main_hot_reload`.

When you run `game.exe` it will load `game.dll` and start the game. In order to hot reload, make some changes to anything in the `game` folder and re-run `build_hot_reload.bat`.

`game.exe` will notice that `game.dll` changed and reload it. The state you wish to keep between reloads goes into the `Game_Memory` struct in `game/game.odin`.

There is also a `build_release.bat` file that makes a `game_release.exe` that does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.dll`, instead it imports the `game` folder as a normal Odin package.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

## Sublime Text

For those who use Sublime Text there's a project file: `project.sublime-project`.

How to use:
- Open the project file in sublime
- Choose the build system `Main Menu -> Tools -> Build System -> Game template` (you can rename the build system by editing `project.sublime-project` manually)
- Compile and run by pressing using F7 / Ctrl + B / Cmd + B
- After you make code changes and want to hot reload, just hit F7 / Ctrl + B / Cmd + B again

## RAD Debugger
Debugging and hot reloading while attached to [RAD Debugger](https://github.com/EpicGamesExt/raddebugger) works with no extra setup.

## VS Code

You can build, debug and hot reload from within VS Code. Open the template using `File -> Open Folder...`.

Requirements for debugging to work:
- Windows: [C++ build tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
- Linux / Mac: [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)

![Image showing  how to start debugging session by selecting Build Hot Reload from the dropdown in the Run and Debug sidebar](https://github.com/user-attachments/assets/95b09772-a19e-400d-9372-06edc8c30484 "Start debugging session by chooing 'Run Hot Reload' and pressing the green arrow button")

Launch with `Run Hot Reload` launch task, see image above. After you make code changes press `Ctrl + Shift + B` to rebuild and hot reload.

## Windows Debugging hacks
On Windows the degugging while hot reloading works by outputting a new PDB each time the game DLL is built. It cleans up the PDBs when you do a fresh start. See `build_hot_reload.bat` for details.

## Demo streams

Streams that start from this template:
- CAR RACER prototype: https://www.youtube.com/watch?v=KVbHJ_CLdkA
- "point & click" prototype: https://www.youtube.com/watch?v=iRvs1Xr1W6o
- Metroidvania / platform prototype: https://www.youtube.com/watch?v=kIxEMchPc3Y
- Top-down adventure prototype: https://www.youtube.com/watch?v=cl8EOjOaoXc

## Atlas builder

The template works nicely together with my [atlas builder](https://github.com/karl-zylinski/atlas-builder). The atlas builder can build an atlas texture from a folder of png or aseprite files. Using an atlas can drastically reduce the number of draw calls your game uses. There's an example in that repository on how to set it up. The atlas generation step can easily be integrated into the build `bat` / `sh` files such as `build_hot_reload.bat`

## Questions?

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

I have a blog post about Hot Reloading here: http://zylinski.se/posts/hot-reload-gameplay-code/

## Have a nice day! /Karl Zylinski
