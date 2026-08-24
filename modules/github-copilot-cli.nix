{
  flake.modules.homeManager.github-copilot-cli =
    { config, lib, ... }:
    let
      configDir = config.programs.github-copilot-cli.configDir;
    in
    {
      options.my.home.github-copilot-cli.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        home = {
          file = {
            "${configDir}/config.json" = {
              force = true;
            };
          };
        };

        programs = {
          github-copilot-cli = lib.recursiveUpdate {
            enable = true;
            enableMcpIntegration = true;
            settings = {
              autoUpdate = false;
              includeCoAuthoredBy = false;
              theme = "dark";
            };
          } config.my.home.github-copilot-cli.overrides;
        };
      };
    };
}
