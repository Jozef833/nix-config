_: {
  flake.modules.homeManager.lazygit =
    { config, lib, ... }:
    {
      options.my.home.lazygit.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          lazygit = lib.recursiveUpdate {
            enable = true;
            settings = {
              disableStartupPopups = true;
              gui = {
                animateExplosion = false;
                nerdFontsVersion = "3";
                scrollHeight = 1;
                showRandomTip = false;
                statusPanelView = "allBranchesLog";
              };
              update = {
                method = "never";
              };
            };
          } config.my.home.lazygit.overrides;
        };
      };
    };
}
