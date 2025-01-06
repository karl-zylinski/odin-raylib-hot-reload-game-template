#!/usr/bin/env bash

# OUT_DIR is for everything except the exe. The exe needs to stay in root
# folder so it sees the assets folder, without having to copy it.
OUT_DIR=build/hot_reload
EXE=game_hot_reload.bin

mkdir -p $OUT_DIR

ROOT=$(odin root)

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
    EXTRA_LINKER_FLAGS="'-Wl,-rpath=\$ORIGIN/linux'"

    # Copy the linux libraries into the project automatically.
    if [ ! -d "$OUT_DIR/linux" ]; then
        mkdir -p $OUT_DIR/linux
        cp -r $ROOT/vendor/raylib/linux/libraylib*.so* $OUT_DIR/linux
    fi
    ;;
esac

# Build the game.
echo "Building game$DLL_EXT"
odin build source -extra-linker-flags:"$EXTRA_LINKER_FLAGS" -define:RAYLIB_SHARED=true -build-mode:dll -out:$OUT_DIR/game_tmp$DLL_EXT -strict-style -vet -debug

# Need to use a temp file on Linux because it first writes an empty `game.so`, which the game will load before it is actually fully written.
mv $OUT_DIR/game_tmp$DLL_EXT $OUT_DIR/game$DLL_EXT

# Do not build the game_hot_reload.bin if it is already running.
# -f is there to make sure we match against full name, including .bin
if pgrep -f game_hot_reload.bin > /dev/null; then
    echo "Hot reloading..."
else
    echo "Building $EXE"
    odin build source/main_hot_reload -out:game_hot_reload.bin -strict-style -vet -debug

    echo "Running $EXE"
    ./$EXE &
fi
