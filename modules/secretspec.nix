_: {
  flake.modules.homeManager.secretspec =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.home.secretspec = {
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        provider = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = {
        xdg.configFile."secretspec/config.toml".source =
          (pkgs.formats.toml { }).generate "secretspec-config.toml"
            (
              lib.recursiveUpdate {
                defaults.provider = config.my.home.secretspec.provider;
              } config.my.home.secretspec.overrides
            );
      };
    };
}
