@echo off

rem First run the stuff in the parent directory, i.e. the atlas builder.
rem It will make atlas.png and atlas.odin based on the stuff in `textures` and `font.ttf`

rem If the atlas builder succeeds then we run the stuff in the current directory,
rem which is the example that shows how to use atlas and do atlased animations.

odin run .. -vet -strict-style && odin run . -vet -strict-style
