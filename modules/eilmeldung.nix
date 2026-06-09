_: {
  flake.modules.homeManager.eilmeldung =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.eilmeldung.homeManager.default ];

      options.my.home.eilmeldung.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          eilmeldung = lib.recursiveUpdate {
            enable = true;
            package = inputs.eilmeldung.packages.${pkgs.stdenv.hostPlatform.system}.eilmeldung;
            settings = {
              input_config = {
                mappings = {
                  "q" = [ "quit" ];
                };
              };
              startup_commands = [ "sync" ];
              sync_every_minutes = 1;
            };
          } config.my.home.eilmeldung.overrides;
        };
      };
    };
}
