@echo off
del Rockman4Practice.nes 2>nul
bass-v10.exe -overwrite -o Rockman4Practice.nes hack.asm
if "%1" == "myriamode" goto fix_saves
goto end

:fix_saves
for %%d in (D:\NES\Mesen\SaveStates\Rockman4Practice_*.mst) do python FixMesenSaveState.py Rockman4Practice.nes %%d

:end
