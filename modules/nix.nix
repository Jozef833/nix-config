_: {
  flake.modules.generic.nix =
    { config, lib, ... }:
    {
      options.my.nix.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        nix = lib.recursiveUpdate {
          settings = {
            experimental-features = [
              "flakes"
              "nix-command"
            ];
            trusted-users = [
              "root"
              "@wheel"
            ];
          };
        } config.my.nix.overrides;
      };
    };
}
