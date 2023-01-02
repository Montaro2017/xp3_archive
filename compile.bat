@echo off
del build /q /s /f
rd build /q /s
mkdir build
dart compile exe bin/xp3_archive.dart -o ./build/xp3_archive.exe