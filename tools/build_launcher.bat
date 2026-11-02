@echo off
rem Builds the launcher (launcher\) with Visual Studio's compiler into out\launcher.
setlocal
for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (echo Visual Studio was not found & exit /b 1)
call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d "%~dp0.." || exit /b 1
cmake -S launcher -B out\launcher -G Ninja -DCMAKE_BUILD_TYPE=Release || exit /b 1
cmake --build out\launcher || exit /b 1
echo Built: %CD%\out\launcher\hulk_launcher.exe
