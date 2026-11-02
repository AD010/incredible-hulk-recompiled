The Incredible Hulk Recompiled
==============================

A COMMUNITY HEAD START, NOT A RELEASE

This build was made so the community has something to start their own The Incredible Hulk PC port from. It was
never meant as a public release and it is not a TekRantGaming (TRG) mainline project.

  * It is not tested or verified. It boots and reaches the first mission, and that is all anyone has seen.
  * You cannot finish the game with it. Expect bugs, crashes and missing features.
  * The source is free for anyone to fork and build on, with credit to TekRantGaming:
    https://github.com/TekRantGaming/incredible-hulk-recompiled

YOU NEED YOUR OWN DISC

Nothing from the game is in this download. You need a disc image (.iso) of your own The Incredible Hulk (USA)
Xbox 360 disc. The port was made from the redump image "Incredible Hulk, The (USA) (En,Fr).iso"; any good copy of
the same game should work (title ID 534507F1).

GETTING STARTED

  1. Unzip this folder anywhere you can write to, such as your Documents or a games folder.
  2. Start hulk_launcher.exe.
  3. Open the game, go to its install page and pick your disc image. The launcher copies the game's files into
     games\incredible_hulk\game (about 4.1 GB).
  4. Press Play.

In game, hold Back and Start together for a second (or Esc for a second and a half) to close the game and return
to the launcher. A controller is recommended.

The game can also be started without the launcher:
  games\incredible_hulk\incredible_hulk.exe --game_data_root=<the copied game folder>

WHERE THINGS ARE KEPT

Inside this folder: the launcher's settings (hulk.txt), the game's settings (games\incredible_hulk\incredible_hulk.toml),
the game's files, its logs and save backups made from the launcher.
Outside it: the game's saves, in Documents\incredible_hulk (where the ReXGlue runtime keeps them).

IF IT CRASHES

The game writes crash-report.txt and its logs in games\incredible_hulk. This build comes with no support: it is a
starting point for others to carry on.

Requirements: Windows 10 or 11, 64 bit, a Direct3D 12 graphics card. Tested only on Windows 11 with an NVIDIA
RTX 4070 Ti.

The Incredible Hulk is a trademark of Marvel. This project is not affiliated with Marvel, Sega or Edge of Reality.
Licences: LICENSE.txt (this project, MIT) and THIRD-PARTY-NOTICES.txt (everything it is built with).
