_: {
  flake.modules.homeManager.opencode =
    { config, lib, ... }:
    {
      options.my.home.opencode.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          opencode = lib.recursiveUpdate {
            enable = true;
            enableMcpIntegration = true;
            settings = {
              autoupdate = false;
              permission = {
                external_directory = {
                  "/nix/**" = "allow";
                  "/tmp/**" = "allow";
                };
                skill = {
                  customize-opencode = "deny";
                };
              };
              share = "disabled";
            };
          } config.my.home.opencode.overrides;
        };
      };
    };
}
