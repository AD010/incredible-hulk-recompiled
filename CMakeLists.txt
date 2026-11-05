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
    src/launcher/native_input_map.cpp
    src/launcher/native_input_win.cpp
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

# Optional native renderer integration. The supplied ZIP contains NativeXRenderer's sources,
# but not its DiligentCore submodule or the required ReXGlue recomp SDK. Build remains
# on Xenos until the Hulk-specific XDK profile is mapped and verified.
option(HULK_WITH_NATIVE_X "Link NativeXRenderer only; Vulkan is not enabled until Hulk profile is verified" OFF)
set(HULK_NATIVE_X_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/native_x_renderer" CACHE PATH
    "Complete NativeXRenderer source tree, with recursively initialized submodules")
if(HULK_WITH_NATIVE_X)
    if(NOT REXSDK_DIR)
        message(FATAL_ERROR "HULK_WITH_NATIVE_X requires -DREXSDK_DIR=<rexglue-sdk recomp source tree>")
    endif()
    if(NOT EXISTS "${REXSDK_DIR}/RECOMP.md")
        message(FATAL_ERROR "Expected ElGuslml/rexglue-sdk branch recomp (missing RECOMP.md)")
    endif()
    if(NOT EXISTS "${HULK_NATIVE_X_SOURCE_DIR}/CMakeLists.txt")
        message(FATAL_ERROR "Missing native_x_renderer sources; copy provided NativeXRenderer into native_x_renderer")
    endif()
    if(NOT EXISTS "${HULK_NATIVE_X_SOURCE_DIR}/thirdparty/diligent-core/CMakeLists.txt")
        message(FATAL_ERROR "Missing DiligentCore submodule in native_x_renderer/thirdparty/diligent-core")
    endif()
    add_subdirectory("${HULK_NATIVE_X_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/hulk_native_x_renderer")
    target_sources(incredible_hulk PRIVATE src/native_x_renderer_hulk.cpp)
    target_link_libraries(incredible_hulk PRIVATE native_x_renderer::native_x_renderer)
    native_x_renderer_copy_runtime(incredible_hulk)
    target_compile_definitions(incredible_hulk PRIVATE HULK_NATIVE_X_LINKED=1)
    # NOTE: NativeXRenderer::Initialize is intentionally NOT called until its XDK
    # device/object layouts and function hooks are verified for Hulk XDK 2.0.6534.
endif()

# PM4 address evidence only; this never redirects drawing. opt-in developer tool.
option(HULK_XDK_PM4_PROBE "Log limited hits at candidate XDK PM4 builders" OFF)
if(HULK_XDK_PM4_PROBE)
    target_sources(incredible_hulk PRIVATE src/xdk_pm4_probe.cpp)
endif()

# Read-only diagnostics: Xbox controller pollers identified in the supplied recomp EXE.
# These probes ONLY log and call through. They do not provide direct mouse/camera input.
option(HULK_GAME_INPUT_PROBE "Trace controller polling callsites (developer only)" OFF)
if(HULK_GAME_INPUT_PROBE)
    target_sources(incredible_hulk PRIVATE src/game_input_probe.cpp)
endif()

string(REPLACE "." "," HULK_VERSION_COMMAS "${HULK_VERSION}")
target_compile_definitions(incredible_hulk PRIVATE
    HULK_VERSION="${HULK_VERSION}" HULK_VERSION_COMMAS=${HULK_VERSION_COMMAS},0
    # Developer aids (HULK_DEV_PAD, HULK_DUMP_IMAGE) only outside release builds.
    $<$<NOT:$<CONFIG:Release>>:HULK_DEV_TOOLS>)

# A link map of every build, kept with each release (release-maps/<version>) to read crash addresses later.
if(WIN32)
    target_link_options(incredible_hulk PRIVATE "LINKER:/MAP:${CMAKE_CURRENT_BINARY_DIR}/incredible_hulk.map")
endif()
