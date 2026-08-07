_: {
  flake.modules.homeManager.gh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.home.gh.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          gh = lib.recursiveUpdate {
            enable = true;
            extensions = with pkgs; [
              gh-aw
              gh-stack
            ];
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
