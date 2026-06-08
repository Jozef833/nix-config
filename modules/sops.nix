_: {
  flake.modules.generic.sops =
    { config, lib, ... }:
    {
      options.my.sops = {
        ageKeyFile = lib.mkOption {
          type = lib.types.str;
        };
        defaultSopsFile = lib.mkOption {
          type = lib.types.path;
        };
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        secrets = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                owner = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = { };
        };
      };

      config = {
        sops = lib.recursiveUpdate {
          age = {
            keyFile = config.my.sops.ageKeyFile;
          };
          defaultSopsFile = config.my.sops.defaultSopsFile;
          secrets = config.my.sops.secrets;
        } config.my.sops.overrides;
      };
    };
}
