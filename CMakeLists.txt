# incredible_hulk - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(incredible_hulk LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(generated/rexglue.cmake)

# Sources
set(INCREDIBLEHULK_SOURCES
    src/main.cpp
    src/crash_report.cpp
    # TRG Launcher 2.0 game side (third_party/trg-launcher/launcher2/game_side)
    src/launcher/input_hook.cpp
    src/launcher/return_to_launcher.cpp
    src/launcher/game_window.cpp
)

if(WIN32)
    add_executable(incredible_hulk WIN32 ${INCREDIBLEHULK_SOURCES})
else()
    add_executable(incredible_hulk ${INCREDIBLEHULK_SOURCES})
endif()

rexglue_setup_target(incredible_hulk GPU_PLUGINS xenos)
