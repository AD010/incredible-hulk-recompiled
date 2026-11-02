# The Incredible Hulk Recompiled

> **A head start for the community, not a release.**
>
> Members of the community asked TekRantGaming for help with a PC port of The Incredible Hulk. This repository is
> that help: a working base to fork and build your own project on. It was never meant for a public release and it
> is not a TekRantGaming (TRG) mainline project.
>
> * **It is not tested or verified.** It boots and reaches the first mission, and that is all anyone has seen.
> * **You cannot finish the game with it.** Expect bugs, crashes and missing features.
> * **TRG Launcher is built in, but optional.** The game runs on its own, and a fork can keep the launcher, change
>   it or drop it.
> * **It is free for anyone to use.** Fork it, change it, ship it, rename it: do whatever you want with the code
>   (see [LICENSE](LICENSE)).
>
> No support is offered here. Take it and make it yours.

A native PC recompilation of the Xbox 360 game **The Incredible Hulk** (Edge of Reality for Sega, 2008), made with
[ReXGlue](https://github.com/rexglue/rexglue-sdk) and set up with
[TRG Launcher 2.0](https://github.com/TekRantGaming/trg-launcher). See **Status** for exactly how far it gets.

You need your own copy of the game. Nothing from the game is in this repository: no disc image, no game files and
none of the code made from them. Each person makes those from their own disc with the steps below.

## Status

| Stage | State |
| --- | --- |
| Codegen | passes with the function lists in this repository |
| Build | game and launcher build on Windows with Visual Studio's clang |
| Launcher | installs from the disc image, writes the settings, starts the game and comes back when it closes |
| Game | boots, plays the intro movies, makes its game data, reaches the main menu and loads into the first story mission with its HUD (2 Nov 2026) |

Only that much was played, with scripted button presses (`HULK_DEV_PAD`, below), never with a real controller. Not
checked: moving and fighting, audio by ear, saving and loading, later missions, frame rate. The first boot screen
draws its text as empty boxes (the autosave notice and menus after it are fine). Tested only on Windows 11 with an
NVIDIA RTX 4070 Ti, Direct3D 12. Linux, Vulkan, AMD and Intel are untested.

## What you need

* Windows 10 or 11, Visual Studio 2022 (or its Build Tools) with the C++ tools and its LLVM clang, CMake 3.25 or
  newer, Ninja, Git and Python 3 with Pillow (only for the logo).
* Your own disc image of **The Incredible Hulk (USA) (En,Fr)**, title ID 534507F1. The port was made from the
  redump image: 7,835,492,352 bytes, SHA1 8BED63B106CFE9F7B1DCF8069110CBF57259BB93. Other good copies of the same
  game should work; only the title ID is checked.

## Building

All commands run from the repository folder. TRG Launcher is a submodule: clone with `git clone --recursive`, or run
`git submodule update --init` after cloning.

1. **The SDK, from source.** The official ReXGlue 0.10.0 Windows zip's `rexruntime.dll` is flagged by about 20 of
   70 antivirus engines on VirusTotal (most likely false positives on an unsigned build, but players would get
   that DLL), so this project builds the SDK itself from the tagged source:

   ```bat
   git clone --branch v0.10.0 --depth 1 https://github.com/rexglue/rexglue-sdk.git sdk-src
   git -C sdk-src submodule update --init --recursive --depth 1
   python tools\fix_symlinks.py sdk-src
   tools\build_sdk.bat
   ```

   `fix_symlinks.py` replaces links that git on Windows checks out as small text files (libmspack's); without it the
   build stops in `lzxd.c`. The SDK's install step adds itself to CMake's user package registry; the game build
   names its SDK folder, so another SDK on the PC is never picked up.

2. **The game's files.** Copy everything off your disc image into `game\`:

   ```bat
   python tools\extract_xiso.py "path\to\Incredible Hulk, The (USA) (En,Fr).iso" game
   ```

3. **Codegen and the game.**

   ```bat
   tools\build_game.bat
   ```

   The build runs codegen first (`incredible_hulk_manifest.toml`). Use `tools\build_game.bat symbols` for a build
   with `incredible_hulk.pdb`, which gives the crash report function names.

4. **The launcher.**

   ```bat
   tools\build_launcher.bat
   ```

## Running

The launcher keeps everything beside itself. Make a folder with `hulk_launcher.exe` in it and the game's program in
`games\incredible_hulk\` (`incredible_hulk.exe`, `rexruntime.dll`, `rexgpu-xenos.dll`). Start the launcher and pick
your disc image on the install page: it copies the game's files into `games\incredible_hulk\game`. Play starts the
game; holding Back and Start (or Esc) in game closes it and the launcher comes back.

To start the game without the launcher:

```bat
incredible_hulk.exe --game_data_root=E:\path\to\game --user_data_root=E:\path\to\saves
```

`tools\run_test.ps1` does that for a test copy in `runs\play`, and `tools\bgwin\bgwin.exe` (built from
`tools\bgwin\bgwin.cs` with the .NET Framework's `csc`) keeps test windows behind yours.

Test aids, none of them needed to play:

* `HULK_DEV_PAD=a@12,start@16,a@20,start@24,a@28,start@32,a@38,a@46,a@54,a@62,a@70,a@80` presses buttons on
  controller 1 at those seconds, with no pad plugged in. That list goes from a fresh start to the first mission.
* `tools\capture_window.ps1 -ProcessId <game> -Out runs\shot -Times 30,60` saves pictures of the game window
  without bringing it forward, and `tools\contact_sheet.py` puts several on one sheet.
* `crash-report.txt` appears beside the exe when the game crashes, with the call stack (names with the symbols
  build).

## How the code was found

The analysis in ReXGlue 0.10.0 misses many of this game's functions. Three lists in this repository fill the gaps;
regenerate them after any change to the SDK or the manifest:

| File | Made by | Holds |
| --- | --- | --- |
| `missing_funcs.toml` | `tools/missing_funcs.py runs/codegen.log` | branch targets codegen reported as "target not in any function". Run codegen, then the script, until codegen passes |
| `indirect_funcs.toml` | `tools/find_missing_funcs.py runs/image.bin` | functions reached only through pointers (vtables, callback tables), which otherwise stop the game with "Call to invalid or unregistered function". Start the game once with `HULK_DUMP_IMAGE=runs\image.bin` to write the image the script reads, and run codegen with `--log-level debug` into `runs\codegen_debug.log` first so it leaves out addresses inside known functions |

The import thunks sit inside this game's code rather than at its end, which the scanner handles.

Never list the register save and restore helpers (from 0x827377B0) as functions: each entry falls through to the
next, and splitting them makes a prologue save one register instead of many. The game then crashes in its heap
setup at start (a write to 0x000F0005). The scanner only takes addresses right after a return or a branch, which
leaves them out.

## The launcher contract

The game side of TRG Launcher 2.0 is in `src/launcher` (setting prefix `hulk_`, flag `--hulk_from_launcher=true`):

* `input_hook.cpp`: the game's XInputGetState wrapper `sub_828AA818`. Every Xam input call goes through one lock, and
  a failed read leaves a zeroed state as on the console.
* `return_to_launcher.cpp`, `game_window.cpp`: from the launcher's `game_side/shared`, renamed.

The launcher rows for the frame rate limiter, upscaler modes, controller options and achievement pop up are off in
`launcher/project.cpp` until their game side hooks are written (see trg-launcher's `launcher2/game_side`).

**Without the launcher:** start `incredible_hulk.exe` yourself (see **Running**); the launcher is never needed. To
take it out of a fork completely, delete `launcher/`, `third_party/trg-launcher` (and its entry in `.gitmodules`),
`tools/build_launcher.bat`, and `return_to_launcher.cpp` and `game_window.cpp` from `src/launcher` and
`CMakeLists.txt`, then remove the two calls to them in `input_hook.cpp`. Keep the rest of `input_hook.cpp`: its lock
and the zeroed state on a failed read help the game with or without a launcher.

## If you publish your own fork

`launcher/project.cpp` has an empty `repo` (no updates until it is set), no Discord link and no Add to Steam art.
The playbook's release chapters (updater, antivirus, crash reports) apply:
[xbox360-recomp-playbook](https://github.com/TekRantGaming/xbox360-recomp-playbook).

## Credits

* [ReXGlue SDK](https://github.com/rexglue/rexglue-sdk) and the projects it builds on.
* [TRG Launcher](https://github.com/TekRantGaming/trg-launcher) by TekRantGaming.
* Game art in the launcher comes from [SteamGridDB](https://www.steamgriddb.com) (game 1214) when it runs.

## Licence

This project's own code is released into the public domain under [the Unlicense](LICENSE): use it for anything,
with or without credit. The parts it uses keep their own licences: TRG Launcher is MIT licensed, and the ReXGlue
SDK and the libraries it builds have theirs.

The Incredible Hulk is a trademark of Marvel. This project is not affiliated with Marvel, Sega or Edge of Reality.
