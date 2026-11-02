# incredible_hulk - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(incredible_hulk LANGUAGES CXX)
if(WIN32)
    enable_language(RC)
endif()

# The version shown in the exe's file details; the launcher's is in launcher/CMakeLists.txt.
set(HULK_VERSION 0.0.1)

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
    # File details, and a manifest that makes the ANSI code page UTF-8 so accented paths work (playbook chapter 2).
    list(APPEND INCREDIBLEHULK_SOURCES src/incredible_hulk.rc src/incredible_hulk.manifest)
    add_executable(incredible_hulk WIN32 ${INCREDIBLEHULK_SOURCES})
else()
    add_executable(incredible_hulk ${INCREDIBLEHULK_SOURCES})
endif()

rexglue_setup_target(incredible_hulk GPU_PLUGINS xenos)

string(REPLACE "." "," HULK_VERSION_COMMAS "${HULK_VERSION}")
target_compile_definitions(incredible_hulk PRIVATE
    HULK_VERSION="${HULK_VERSION}" HULK_VERSION_COMMAS=${HULK_VERSION_COMMAS},0
    # Developer aids (HULK_DEV_PAD, HULK_DUMP_IMAGE) only outside release builds.
    $<$<NOT:$<CONFIG:Release>>:HULK_DEV_TOOLS>)

# A link map of every build, kept with each release (release-maps/<version>) to read crash addresses later.
if(WIN32)
    target_link_options(incredible_hulk PRIVATE "LINKER:/MAP:${CMAKE_CURRENT_BINARY_DIR}/incredible_hulk.map")
endif()
