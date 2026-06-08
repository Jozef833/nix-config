_: {
  flake.modules.nixos.base =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.nixos = {
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        primaryUser = lib.mkOption {
          type = lib.types.str;
        };
        stateVersion = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = {
        nix = {
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 30d";
          };
          optimise = {
            automatic = true;
            dates = "weekly";
          };
        };

        system = lib.recursiveUpdate {
          stateVersion = config.my.nixos.stateVersion;
        } (config.my.nixos.overrides.system or { });
      };
    };
}
