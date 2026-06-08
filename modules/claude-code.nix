_: {
  flake.modules.homeManager.claude-code =
    { config, lib, ... }:
    {
      options.my.home.claude-code.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          claude-code = lib.recursiveUpdate {
            enable = true;
            enableMcpIntegration = true;
            settings = {
              attribution = {
                commit = "";
                pr = "";
              };
              autoMemoryEnabled = false;
              disableDeepLinkRegistration = "disable";
              editorMode = "vim";
              env = {
                CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
                CLAUDE_CODE_NO_FLICKER = 1;
                DISABLE_EXTRA_USAGE_COMMAND = 1;
                DISABLE_INSTALL_GITHUB_APP_COMMAND = 1;
                DISABLE_INSTALLATION_CHECKS = 1;
              };
              permissions = {
                defaultMode = "auto";
                deny = [
                  "Bash(find /*)"
                ];
              };
              showThinkingSummaries = true;
              theme = "dark";
              workflowKeywordTriggerEnabled = false;
            };
          } config.my.home.claude-code.overrides;
        };
      };
    };
}
