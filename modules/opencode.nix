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
              agent = {
                build = {
                  permission = {
                    task = "ask";
                  };
                };
                plan = {
                  permission = {
                    task = "ask";
                  };
                };
              };
              autoupdate = false;
              lsp = true;
              permission = {
                bash = {
                  "find /*" = "deny";
                };
                external_directory = {
                  "/nix/**" = "allow";
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
