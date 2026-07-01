_: {
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
