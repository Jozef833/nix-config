_: {
  flake.modules.nixos.xdg-portal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.nixos.xdg-portal.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        xdg = {
          portal = lib.recursiveUpdate {
            enable = true;
            extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
            config = {
              common = {
                default = "gtk";
              };
            };
          } config.my.nixos.xdg-portal.overrides;
        };
      };
    };
}
