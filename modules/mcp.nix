_: {
  flake.modules.homeManager.mcp =
    {
      config,
      inputs,
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
              chrome-devtools = {
                disabled = true;
                args = [
                  "--executable-path=${pkgs.chromium}/bin/chromium"
                  "--isolated"
                  "--no-performance-crux"
                  "--no-usage-statistics"
                ];
                command = "${
                  inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.chrome-devtools-mcp
                }/bin/chrome-devtools-mcp";
                env = {
                  CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS = "1";
                };
              };
              exa = {
                disabled = true;
                url = "https://mcp.exa.ai/mcp";
              };
              # playwright = {
              #   disabled = true;
              #   args = [ "--isolated" ];
              #   command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
              # };
            };
          } config.my.home.mcp.overrides;
        };
      };
    };
}
