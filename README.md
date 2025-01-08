# Odin + Raylib + Hot Reload template

This is an [Odin](https://github.com/odin-lang/Odin) + [Raylib](https://github.com/raysan5/raylib) game template with [Hot Reloading](http://zylinski.se/posts/hot-reload-gameplay-code/) pre-setup. It makes it possible to reload gameplay code while the game is running.

Supported platforms: Windows, macOS, Linux and [web](#web-build).

Supported editors and debuggers: [Sublime Text](#sublime-text), [VS Code](#vs-code) and [RAD Debugger](#rad-debugger).

![hot_reload gif](https://github.com/user-attachments/assets/18059ab2-0878-4617-971d-e629a969fc93)

See The Legend of Tuna repository for an example project that also uses Box2D: https://github.com/karl-zylinski/the-legend-of-tuna

I used this kind of hot reloading while developing my game [CAT & ONION](https://store.steampowered.com/app/2781210/CAT__ONION/).

## Hot reload quick start

> [!NOTE]
> These instructions use some Windows terminology. If you are on mac / linux, then replace these words:
> - `bat` -> `sh`
> - `exe` -> `bin`
> - `dll` -> `dylib` (mac), `so` (linux)

1. Run `build_hot_reload.bat` to create `game_hot_reload.exe` and `game.dll` (located in `build/hot_reload`). Note: It expects odin compiler to be part of your PATH environment variable.
2. Run `game_hot_reload.exe`, leave it running.
3. Make changes to the gameplay code in `source/game.odin`. For example, change the line `rl.ClearBackground(rl.BLACK)` so that it instead uses `rl.BLUE`. Save the file.
4. Run `build_hot_reload.bat`, it will recompile `game.dll`.
5. The running `game_hot_reload.exe` will see that `game.dll` changed and reload it. But it will use the same `Game_Memory` (a struct defined in `source/game.odin`) as before. This will make the game use your new code without having to restart.

Note, in step 4: `build_hot_reload.bat` does not rebuild `game_hot_reload.exe`. It checks if `game_hot_reload.exe` is already running. If it is, then it skips compiling it.

## Release builds

Run `build_release.bat` to create a release build in `build/release`. That exe does not have the hot reloading stuff, since you probably do not want that in the released version of your game. This means that the release version does not use `game.dll`, instead it imports the `source` folder as a normal Odin package.

`build_debug.bat` is like `build_release.bat` but makes a debuggable executable, in case you need to debug your non-hot-reload-exe.

## Web build

`build_web.bat` builds a release web executable (no hot reloading!).

### Web build requirements

- Emscripten. Download and install somewhere on your computer. Follow the instructions here: https://emscripten.org/docs/getting_started/downloads.html (follow the stuff under "Installation instructions using the emsdk (recommended)").
- Recent Odin compiler: This uses Raylib binding changes that were done on January 1, 2025.

### Web build quick start

1. Change `EMSCRIPTEN_SDK_DIR` in `build_web.bat/sh` to point to your emscripten setup.
2. Run `build_web.bat/sh`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> You may not be able to start `build/web/index.html` directly, because you'll get "CORS policy" javascript errors. You can get around that by starting a local web server using python. Go into `build/web` and run:
> 
> `python -m http.server`
>
> Open `localhost:8000` in your browser to play the game.
>
> _If you don't have python, then emscripten actually comes with it. Look in the `python` folder of where you installed emscripten._

See https://github.com/karl-zylinski/odin-raylib-web for more info on how the web build works.

See https://github.com/karl-zylinski/the-legend-of-tuna for a gamejam game I made using this template. It supports web builds. In fact, the web build support is ported backwards from that game into this template and the odin-raylib-web repository I mentioned just above.

> [!WARNING]
> The web build relies on emscripten, because raylib requires emscripten in order to work on the web. This comes with some limitations for our Odin code. We can only compile in "freestanding mode", which means we have no operating system support at all. For example, no allocators are automatically set up for us. Therefore I have made sure to setup web-compatible allocators and a logger. This is done by interfacing with the `libc` stuff that emscripten exposes. This also means that some parts of `core` do not work.
>
> If you need to use `os.read_entire_file` on the web, then have a look at the `source/os` package. It implements `read_entire_file` and `write_entire_file` using emscripten libc. Let me know if you need any other OS procs to port your game to the web!

## Assets
You can put assets such as textures, sounds and music in the `assets` folder. That folder will be copied when a release build is created and also integrated into the web build.

The hot reload build doesn't do any copying, because the hot reload executable lives in the root of the repository, alongside the `assets` folder.

## Sublime Text

For those who use Sublime Text there's a project file: `project.sublime-project`.

How to use:
- Open the project file in sublime
- Choose the build system `Main Menu -> Tools -> Build System -> Odin + Raylib + Hot Reload template` (you can rename the build system by editing `project.sublime-project` manually)
- Compile and run by pressing using F7 / Ctrl + B / Cmd + B
- After you make code changes and want to hot reload, just hit F7 / Ctrl + B / Cmd + B again

## RAD Debugger
You can hot reload while attached to [RAD Debugger](https://github.com/EpicGamesExt/raddebugger). Attach to your `game_hot_reload` executable, make code changes in your code editor and re-run the the `build_hot_reload` script to build and hot reload.

## VS Code

You can build, debug and hot reload from within VS Code. Open the template using `File -> Open Folder...`.

Requirements for debugging to work:
- Windows: [C++ build tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
- Linux / Mac: [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)

<img alt="Image showing  how to start debugging session by selecting Build Hot Reload from the dropdown in the Run and Debug sidebar" src="https://github.com/user-attachments/assets/e62d710b-06f1-4833-bb2a-ab95527cf38c" width="50%" title="Start debugging session by chooing 'Run Hot Reload' and pressing the green arrow button">

Launch with `Run Hot Reload` launch task, see image above. After you make code changes press `Ctrl + Shift + B` to rebuild and hot reload.

## Windows Debugging hacks
On Windows the degugging while hot reloading works by outputting a new PDB each time the game DLL is built. It cleans up the PDBs when you do a fresh start. See `build_hot_reload.bat` for details.

## Demo streams

Streams that start from this template:
- 48 hour "Odin Holiday Gamejam": https://www.youtube.com/playlist?list=PLxE7SoPYTef2XC-ObA811vIefj02uSGnB Every minute of the development is documented. The resulting game of the gamejam is here: https://zylinski.itch.io/the-legend-of-tuna
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
