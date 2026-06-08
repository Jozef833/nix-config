_: {
  flake.modules.homeManager.gh =
    { config, lib, ... }:
    {
      options.my.home.gh.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          gh = lib.recursiveUpdate {
            enable = true;
            gitCredentialHelper = {
              enable = false;
            };
            settings = {
              git_protocol = "ssh";
            };
          } config.my.home.gh.overrides;
        };
      };
    };
}
