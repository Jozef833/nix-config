_: {
  flake.modules.homeManager.bash =
    { config, lib, ... }:
    {
      options.my.home.bash.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          bash = lib.recursiveUpdate {
            enable = true;
          } config.my.home.bash.overrides;
        };
      };
    };
}
