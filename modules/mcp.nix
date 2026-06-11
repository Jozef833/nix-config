_: {
  flake.modules.homeManager.mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.home.mcp.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        programs = {
          mcp = lib.recursiveUpdate {
            enable = true;
            servers = {
              exa = {
                disabled = true;
                url = "https://mcp.exa.ai/mcp";
              };
              playwright = {
                disabled = true;
                args = [ "--isolated" ];
                command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
              };
            };
          } config.my.home.mcp.overrides;
        };
      };
    };
}
