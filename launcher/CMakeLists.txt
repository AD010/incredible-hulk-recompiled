# The Incredible Hulk Recompiled's launcher: TRG Launcher 2.0 with launcher/project.cpp.
# Build with tools/build_launcher.bat (Visual Studio's compiler).
cmake_minimum_required(VERSION 3.25)
project(hulk_launcher LANGUAGES C CXX)

set(HULK_LAUNCHER_VERSION 0.0.1)
string(REPLACE "." "," _commas "${HULK_LAUNCHER_VERSION}")

# The launcher runs on its own: the C runtime is linked in.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(TRG_LAUNCHER_STANDALONE ON CACHE BOOL "" FORCE)
set(TRG_LAUNCHER_BUILD_DEMO OFF CACHE BOOL "" FORCE)
set(TRG_LAUNCHER_2 ON CACHE BOOL "" FORCE)
add_subdirectory(../third_party/trg-launcher trg-launcher)

add_executable(hulk_launcher WIN32 project.cpp launcher.rc)
target_link_libraries(hulk_launcher PRIVATE trg::launcher2)
# PROJECT_VERSION is shown in the launcher and compared with releases by its self updater; the .rc file uses both.
target_compile_definitions(hulk_launcher PRIVATE PROJECT_VERSION="${HULK_LAUNCHER_VERSION}"
  PROJECT_VERSION_COMMAS=${_commas},0)
if(MSVC)
  target_compile_options(hulk_launcher PRIVATE /W4 /utf-8 /permissive-)
  # A WIN32 program (no console window) that starts at main().
  target_link_options(hulk_launcher PRIVATE /ENTRY:mainCRTStartup)
endif()
