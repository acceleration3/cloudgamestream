@echo off
rmdir /q /s build
mkdir build
cd build
cmake -G "Visual Studio 16 2019" -A win32 ..
pause