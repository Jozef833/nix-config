_: {
  flake.modules.homeManager.direnv =
    { config, lib, ... }:
    {
      options.my.home.direnv.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          direnv = lib.recursiveUpdate {
            enable = true;
            nix-direnv = {
              enable = true;
            };
          } config.my.home.direnv.overrides;
        };
      };
    };
}
