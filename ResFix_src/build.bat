@echo off
cmake --build build --config Release --target ResFix
mv build/Release/ResFix.exe ../Bin/ResFix/ResFix.exe
pause