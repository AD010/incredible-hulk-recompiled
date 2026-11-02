@echo off
rem Builds the game against the ReXGlue SDK made by tools\build_sdk.bat.
rem   tools\build_game.bat            release build in out\build\win-amd64-release
rem   tools\build_game.bat debug      debug build in out\build\win-amd64-debug
setlocal
set "PRESET=win-amd64-release"
if /i "%1"=="debug" set "PRESET=win-amd64-debug"
if /i "%1"=="symbols" set "PRESET=win-amd64-relwithdebinfo"
for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (echo Visual Studio was not found & exit /b 1)
call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set "PATH=%VSPATH%\VC\Tools\Llvm\x64\bin;%PATH%"
cd /d "%~dp0.." || exit /b 1
set "SDK=%CD%\sdk-src\out\install\win-amd64"
if not exist "%SDK%\bin\rexglue.exe" (echo Build the SDK first: tools\build_sdk.bat & exit /b 1)
rem The SDK's own install registers every SDK build with CMake; name ours so another one is never used.
cmake --preset %PRESET% -DCMAKE_PREFIX_PATH="%SDK%" -DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF || exit /b 1
cmake --build out\build\%PRESET% --parallel || exit /b 1
echo Built: %CD%\out\build\%PRESET%
