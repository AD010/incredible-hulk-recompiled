"""Writes THIRD-PARTY-NOTICES.txt for a release: the licence of every component in the shipped programs.

The game (incredible_hulk.exe, rexruntime.dll, rexgpu-xenos.dll) is built from the ReXGlue SDK in sdk-src and the
libraries under its thirdparty folder; the launcher from trg-launcher with SDL2, Dear ImGui and stb (fetched into
out/launcher/_deps by its build). Catch2 (tests) and MoltenVK (macOS) are not in a Windows build and are left out.

Usage: python tools/make_notices.py <out file>
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SDK = ROOT / "sdk-src"
DEPS = ROOT / "out" / "launcher" / "_deps"
NAMES = ("LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING", "COPYING.LIB", "LICENSE.MIT")
SKIP = {"catch2", "moltenvk"}


def licence_files(folder):
    found = [folder / n for n in NAMES if (folder / n).is_file()]
    if not found:
        found = sorted(p for p in folder.glob("*/*") if p.name in NAMES)[:2]
    return found


def main():
    out = Path(sys.argv[1])
    parts = [("The Incredible Hulk Recompiled", [ROOT / "LICENSE"]),
             ("ReXGlue SDK (rexruntime.dll, rexgpu-xenos.dll, recompiled code support)", [SDK / "LICENSE"])]
    no_file = []
    for d in sorted(p for p in (SDK / "thirdparty").iterdir() if p.is_dir()):
        if d.name in SKIP:
            continue
        files = licence_files(d)
        if files:
            parts.append((f"{d.name} (in the ReXGlue SDK)", files))
        else:
            no_file.append(d.name)
    parts.append(("TRG Launcher (hulk_launcher.exe)", [ROOT / "third_party" / "trg-launcher" / "LICENSE"]))
    for name, folder in (("SDL2 (in hulk_launcher.exe)", "trg_sdl2_src-src"), ("Dear ImGui (in hulk_launcher.exe)",
                         "trg_imgui_src-src"), ("stb (in hulk_launcher.exe)", "trg_stb-src")):
        files = licence_files(DEPS / folder)
        if not files:
            raise SystemExit(f"no licence file in {DEPS / folder}: build the launcher first")
        parts.append((name, files))

    text = ["THIRD PARTY NOTICES", "",
            "The programs in this package contain the components below, each under its own licence.",
            "The Microsoft Visual C++ runtime DLLs (msvcp140*.dll, vcruntime140*.dll) beside the game are",
            "redistributed under the Visual Studio licence terms for redistributable code.", ""]
    if no_file:
        text += ["These parts of the ReXGlue SDK have no licence file of their own and are covered by the ReXGlue",
                 "SDK licence and the Xenia licence it includes: " + ", ".join(no_file) + ".", ""]
    for name, files in parts:
        for f in files:
            text += ["=" * 78, name + ("" if len(files) == 1 else f" ({f.name})"), "=" * 78, "",
                     f.read_text(encoding="utf-8", errors="replace").strip(), ""]
    out.write_text("\r\n".join(text) + "\r\n", encoding="utf-8", newline="")
    print(f"{out}: {sum(len(f) for _, f in parts)} licences")


if __name__ == "__main__":
    main()
