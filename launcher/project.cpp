// The Incredible Hulk Recompiled's launcher: TRG Launcher 2.0 (third_party/trg-launcher/launcher2) with this
// project's details. Every field is described in trg-launcher's launcher2/include/trg/hub.h.

#include <trg/hub.h>

#include "logo_png.h"

namespace {

trg::hub::ProjectConfig Hulk() {
  using trg::hub::GameInfo;
  using trg::hub::InstallSource;

  trg::hub::ProjectConfig p;
  p.name = "The Incredible Hulk Recompiled";
  p.id = "hulk";
  p.version = PROJECT_VERSION;  // from launcher/CMakeLists.txt
  p.home_line = "";
  p.about = "A community head start: a native PC recompilation of the Xbox 360 game The Incredible Hulk, made with "
            "ReXGlue, for anyone to fork and carry on. It is not a release: it is untested, the game cannot be "
            "finished with it, and there will be bugs. It needs your own disc.";
  p.made_by = "Edge of Reality for Sega, 2008";
  p.region = "USA (NTSC)";
  p.logo_png = kHulkLogoPng;
  p.logo_png_size = sizeof kHulkLogoPng;

  // The copy the port was made with: the redump image's hashes, and default.xex's version and media ID.
  GameInfo hulk = {
      "incredible_hulk", "The Incredible Hulk", "incredible_hulk.exe", "IncredibleHulk", 0x534507F1,
      ImVec4(0.46f, 0.77f, 0.20f, 1.0f), "Smash your way across New York.", InstallSource::kDisc,
      // SteamGridDB game 1214 (The Incredible Hulk: The Official Videogame), its highest scored grid, hero and logo.
      // Other grids: grid/869611d6f368d567d107a7dc9a96c3c8.png, grid/add4ec2c53b48e04934ed783dc259013.png
      1214, "grid/715d23d4f13675a97f8c2294614e9126.png", "hero/94b5bde6de888ddf9cde6748ad2523d1.png",
      "logo/9df2afabcdd08dbe0db7a49e509403c9.png",
      "0.0.0.1", "Incredible Hulk, The (USA) (En,Fr).iso", "7,835,492,352 bytes",
      "8BED63B106CFE9F7B1DCF8069110CBF57259BB93", "A29E46CC110BC7122DD538EFB627040E", "C7F02A2D", "347A80F6",
      "about 4.1 GB"};
  p.games = {hulk};

  // Releases. Set repo to the project's GitHub repository before the first release.
  p.repo = "";
  p.packages_tag_prefix = "packages-v";
  p.launcher_zip = "IncredibleHulk";
  p.launcher_exe = "hulk_launcher";
  p.linux_data_folder = "incredible_hulk";

  // The contract with the game (src/launcher in the game).
  p.setting_prefix = "hulk_";
  p.from_launcher_flag = "--hulk_from_launcher=true";
  p.test_background_env = "HULK_TEST_BACKGROUND";
  p.release_server_env = "HULK_RELEASE_SERVER";
  // Rows whose game side hooks are not in the game yet (launcher2/game_side): the frame rate limiter, the upscaler
  // modes, the controller options and the achievement pop up.
  p.features.frame_rate = false;
  p.features.render_quality = false;
  p.features.controller_options = false;
  p.features.achievement_toasts = false;

  p.discord_url = "";
  p.steam_art_base = "";
  return p;
}

}  // namespace

int main(int argc, char** argv) { return trg::hub::Run(Hulk(), argc, argv); }
