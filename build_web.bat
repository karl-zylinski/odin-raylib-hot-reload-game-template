:: This script creates a web build. It builds the game with wasm32 architecture,
:: but without any OS support (freestanding). It then uses emscripten to compile
:: a small C program that is the entry point of the web build. That C program
:: calls the Odin code.
::
:: Being built in freestanding mode, the Odin code has no allocator set up by
:: default. I work around this by setting up an allocator that uses the C
:: standard library that emscripten exposes. See the stuff in `source/main_web`
:: for more info.
::
:: Also, see this separate repository for more detailed information on how this
:: kind of web build works:
:: https://github.com/karl-zylinski/odin-raylib-web

@echo off

:: Set this to point to where you installed emscripten.
set EMSCRIPTEN_SDK_DIR=c:\emsdk
set OUT_DIR=build\web

if not exist %OUT_DIR% mkdir %OUT_DIR%

set EMSDK_QUIET=1
call %EMSCRIPTEN_SDK_DIR%\emsdk_env.bat

:: Note RAYLIB_WASM_LIB=env.o -- This env.o thing is the object file that
:: contains things linked into the WASM binary. You can see how RAYLIB_WASM_LIB
:: is used inside <odin>/vendor/raylib/raylib.odin.
::
:: We have to do it this way because the emscripten compiler (emcc) needs to be
:: fed the precompiled raylib library file. That stuff will end up in env.o,
:: which our Odin code is instructed to link to.
::
:: If you want to use raygui, then add:
::     -define:RAYGUI_WASM_LIB=env.o
:: and add the following at to the `files` variable declared a few lines down:
::     ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a
odin build source\main_web -target:freestanding_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -vet -strict-style -o:speed -out:%OUT_DIR%\game
IF %ERRORLEVEL% NEQ 0 exit /b 1

for /f %%i in ('odin root') do set "ODIN_PATH=%%i"

set files=source\main_web\main_web.c %OUT_DIR%\game.wasm.o %ODIN_PATH%\vendor\raylib\wasm\libraylib.a
set flags=-sUSE_GLFW=3 -sASYNCIFY -sASSERTIONS -DPLATFORM_WEB --shell-file source\main_web\index_template.html --preload-file assets

:: add `-g` to `emcc` call to enable debug symbols (works in chrome).
::
:: We use cmd /c here because emcc tends to steal the whole command prompt, so
:: nothing after it is ever run, regardless of if it succeeds or not.
cmd /c emcc -o %OUT_DIR%\index.html %files% %flags%

del %OUT_DIR%\game.wasm.o 

echo Web build created in %OUT_DIR%