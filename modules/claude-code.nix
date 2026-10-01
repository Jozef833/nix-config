{
  flake.modules.homeManager.claude-code =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      manifest = lib.importJSON ./claude-code-manifest.zst.json;
      package =
        if lib.versionOlder pkgs.claude-code.version manifest.version then
          pkgs.claude-code.override { inherit manifest; }
        else
          pkgs.claude-code;
    in
    {
      options.my.home.claude-code.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          claude-code = lib.recursiveUpdate {
            enable = true;
            inherit package;
            settings = {
              attribution = {
                commit = "";
                pr = "";
              };
              autoMemoryEnabled = false;
              disableBundledSkills = true;
              disableDeepLinkRegistration = "disable";
              editorMode = "vim";
              env = {
                CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
                CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL = 1;
                CLAUDE_CODE_NO_FLICKER = 1;
                DISABLE_EXTRA_USAGE_COMMAND = 1;
                DISABLE_INSTALL_GITHUB_APP_COMMAND = 1;
              };
              forceLoginMethod = "claudeai";
              lspRecommendationDisabled = true;
              permissions = {
                defaultMode = "bypassPermissions";
              };
              showThinkingSummaries = true;
              skipDangerousModePermissionPrompt = true;
              theme = "dark";
              workflowKeywordTriggerEnabled = false;
            };
          } config.my.home.claude-code.overrides;
        };
      };
    };
}
