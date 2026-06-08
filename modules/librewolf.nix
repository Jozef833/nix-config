_: {
  flake.modules.homeManager.librewolf =
    { config, lib, ... }:
    {
      options.my.home.librewolf.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          librewolf = lib.recursiveUpdate {
            enable = true;
          } config.my.home.librewolf.overrides;
        };
      };
    };
}
