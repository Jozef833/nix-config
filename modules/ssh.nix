_: {
  flake.modules.homeManager.ssh =
    { config, lib, ... }:
    {
      options.my.home.ssh.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          ssh = lib.recursiveUpdate {
            enable = true;
            enableDefaultConfig = false;
            settings = { };
          } config.my.home.ssh.overrides;
        };

        services = {
          ssh-agent = {
            enable = true;
          };
        };
      };
    };
}
