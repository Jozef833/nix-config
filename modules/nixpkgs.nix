_: {
  flake.modules.generic.nixpkgs =
    { config, lib, ... }:
    {
      options.my.nixpkgs.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        nixpkgs = lib.recursiveUpdate {
          config = {
            allowUnfree = false;
          };
        } config.my.nixpkgs.overrides;
      };
    };
}
