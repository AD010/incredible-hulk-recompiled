// incredible_hulk - ReXGlue Recompiled Project
//
// Customize your app by overriding virtual hooks from rex::ReXApp.

#pragma once

#include <cstdio>
#include <cstdlib>

#include <rex/rex_app.h>
#include <rex/system/xmemory.h>

namespace hulk {
void InstallCrashReport();  // crash_report.cpp
}  // namespace hulk

class IncredibleHulkApp : public rex::ReXApp {
 public:
  using rex::ReXApp::ReXApp;

  static std::unique_ptr<rex::ui::WindowedApp> Create(
      rex::ui::WindowedAppContext& ctx) {
    return std::unique_ptr<IncredibleHulkApp>(new IncredibleHulkApp(ctx, "incredible_hulk",
        PPCImageConfig));
  }

  // Override virtual hooks for customization:
  // void OnPostInitLogging() override {}
  // The Xenos GPU emulation is the renderer; the gpu_plugin setting can still name another.
  void OnPreSetup(rex::RuntimeConfig& config) override {
    if (config.gpu_plugin.empty()) config.gpu_plugin = "xenos";
  }
  // void OnLoadXexImage(std::string& xex_image) override {}
  // Developer aid (not in release builds): HULK_DUMP_IMAGE=<file> writes the loaded game image (from image_base) to that file, for
  // tools/find_missing_funcs.py, which looks for functions reached only through pointers.
  void OnPostLoadXexImage() override {
#if defined(HULK_DEV_TOOLS)
    const char* out = std::getenv("HULK_DUMP_IMAGE");
    if (!out || !*out) return;
    const uint8_t* image = runtime()->memory()->TranslateVirtual(PPCImageConfig.image_base);
    if (FILE* f = std::fopen(out, "wb")) {
      std::fwrite(image, 1, PPCImageConfig.image_size, f);
      std::fclose(f);
    }
#endif
  }
  // After the runtime's own exception handlers are in place (crash_report.cpp).
  void OnPostSetup() override { hulk::InstallCrashReport(); }
  // void OnCreateDialogs(rex::ui::ImGuiDrawer* drawer) override {}
  // std::unique_ptr<rex::ui::ImGuiDialog> CreateAchievementsOverlay() override;
  // std::unique_ptr<rex::ui::AchievementNotificationDialog>
  // CreateAchievementNotificationDialog() override;
  // void OnShutdown() override {}
  // void OnConfigurePaths(rex::PathConfig& paths) override {}
};
