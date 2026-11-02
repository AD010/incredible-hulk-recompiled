@echo off
rem Builds the ReXGlue SDK from source (sdk-src, tag v0.10.0) with Visual Studio's clang.
rem The result lands in sdk-src\out\install\win-amd64, which the game build points at.
setlocal
for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (echo Visual Studio was not found & exit /b 1)
call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set "PATH=%VSPATH%\VC\Tools\Llvm\x64\bin;%PATH%"
cd /d "%~dp0..\sdk-src" || exit /b 1
clang --version | findstr version
cmake --preset win-amd64 || exit /b 1
cmake --build out/build/win-amd64 --config Release --target install --parallel || exit /b 1
echo Built: %CD%\out\install\win-amd64
