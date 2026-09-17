{
  flake.modules.homeManager.zed-editor =
    { config, lib, ... }:
    {
      options.my.home.zed-editor.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          zed-editor = lib.recursiveUpdate {
            enable = true;
            enableMcpIntegration = true;
            userSettings = {
              auto_update = false;
            };
          } config.my.home.zed-editor.overrides;
        };
      };
    };
}
