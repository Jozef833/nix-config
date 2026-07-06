_: {
  flake.modules.homeManager.ungoogled-chromium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.home.ungoogled-chromium.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          chromium = lib.recursiveUpdate {
            enable = true;
            extensions = [
              "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
            ];
            package = pkgs.ungoogled-chromium;
          } config.my.home.ungoogled-chromium.overrides;
        };
      };
    };
}
