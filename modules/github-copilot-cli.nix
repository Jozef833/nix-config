{
  flake.modules.homeManager.github-copilot-cli =
    { config, lib, ... }:
    {
      options.my.home.github-copilot-cli.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          github-copilot-cli = lib.recursiveUpdate {
            enable = true;
            enableMcpIntegration = true;
            mutableSettings = true;
            settings = {
              autoUpdate = false;
              defaultPermissionMode = "allow-all";
              disabledSkills = [
                "customize-cloud-agent"
                "github-pr-media"
              ];
              editorMode = "vim";
              includeCoAuthoredBy = false;
              theme = "dark";
            };
          } config.my.home.github-copilot-cli.overrides;
        };
      };
    };
}
