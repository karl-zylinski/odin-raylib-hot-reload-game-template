This is a small game template for Odin + Raylib with hot reloading pre-setup. It contains stuff that my different game projects had in common, so I made this template so I can get up and running quicker.

`build_dev.bat` will build game.dll from the stuff in this directory. It will also build a game.exe from the stuff in `main_hot_reload`. When you run game.exe it will load game.dll and reload it anytime it changes. The state you wish to keep between reloads goes into the GameMemory struct in `game.odin`.

There is also a `build_release.bat` file that makes a game_release.exe that does not have the hot reloading stuff, since you probably do not want that in the released version of your game.

Edit `build_dev_main.bat` so it uses the correct path to copy `raylib.dll` from.

There's a `project.sublime-project` in case you use sublime. Edit it and make sure the paths to the folders within the Odin compiler directory are correct. I put those as part of my project so I can quickly jump to symbol within core & raylib.

There are also some additional files with some helpers that I find useful.

Ask questions in my gamedev Discord: https://discord.gg/4FsHgtBmFK

Have a nice day!
/Karl Zylinski
