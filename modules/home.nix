_: {
  flake.modules.homeManager.home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.home = {
        extraAliases = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
        };
        extras = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        stateVersion = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = {
        home = lib.recursiveUpdate {
          packages =
            with pkgs;
            [
              devenv
              eza
              nerd-fonts.jetbrains-mono
              ripgrep
            ]
            ++ config.my.home.extras;
          shellAliases = {
            lg = "lazygit";
            tree = "eza -T";
          }
          // config.my.home.extraAliases;
          stateVersion = config.my.home.stateVersion;
        } config.my.home.overrides;
      };
    };
}
