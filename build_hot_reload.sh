#!/usr/bin/env bash

mkdir -p build

# NOTE: this is a recent addition to the Odin compiler, if you don't have this command
# you can change this to the path to the Odin folder that contains vendor, eg: "~/Odin".
ROOT=$(odin root)
if [ ! $? -eq 0 ]; then
    echo "Your Odin compiler does not have the 'odin root' command, please update or hardcode it in the script."
    exit 1
fi

set -eu

# Figure out the mess that is dynamic libraries.
case $(uname) in
"Darwin")
    case $(uname -m) in
    "arm64") LIB_PATH="macos-arm64" ;;
    *)       LIB_PATH="macos" ;;
    esac

    DLL_EXT=".dylib"
    EXTRA_LINKER_FLAGS="-Wl,-rpath $ROOT/vendor/raylib/$LIB_PATH"
    ;;
*)
    DLL_EXT=".so"
    EXTRA_LINKER_FLAGS="'-Wl,-rpath=\$ORIGIN/../linux'"

    # Copy the linux libraries into the project automatically.
    if [ ! -d "linux" ]; then
        mkdir linux
        cp -r $ROOT/vendor/raylib/linux/libraylib*.so* linux
    fi
    ;;
esac

# Build the game.
echo "Building game$DLL_EXT"
odin build game -extra-linker-flags:"$EXTRA_LINKER_FLAGS" -define:RAYLIB_SHARED=true -build-mode:dll -out:build/game_tmp$DLL_EXT -strict-style -vet -debug

# Need to use a temp file on Linux because it first writes an empty `game.so`, which the game will load before it is actually fully written.
mv build/game_tmp$DLL_EXT build/game$DLL_EXT

# Do not build the game_hot_reload.bin if it is already running.
# -f is there to make sure we match against full name, including .bin
if pgrep -f game_hot_reload.bin > /dev/null; then
    echo "Game running, hot reloading..."
    exit 0
else
    echo "Building game_hot_reload.bin"
    odin build main_hot_reload -out:build/game_hot_reload.bin -strict-style -vet -debug
fi
