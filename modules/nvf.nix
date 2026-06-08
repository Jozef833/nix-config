_: {
  flake.modules.homeManager.nvf =
    { config, lib, ... }:
    {
      options.my.home.nvf = {
        languages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "csharp"
            "css"
            "html"
            "lua"
            "markdown"
            "nix"
            "python"
            "rust"
            "sql"
            "typescript"
            "yaml"
          ];
        };
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };

      config = {
        programs = {
          nvf = lib.recursiveUpdate {
            enable = true;
            defaultEditor = true;
            enableManpages = true;
            settings = {
              vim = {
                autopairs = {
                  nvim-autopairs = {
                    enable = true;
                  };
                };
                languages = lib.mkMerge [
                  {
                    enableExtraDiagnostics = true;
                    enableTreesitter = true;
                  }
                  (lib.genAttrs config.my.home.nvf.languages (_: {
                    enable = true;
                  }))
                ];
                lineNumberMode = "relNumber";
                lsp = {
                  enable = true;
                };
                luaConfigRC = {
                  default = ''
                    vim.opt.expandtab = true
                    vim.opt.mousescroll = "ver:1"
                  '';
                };
                options = {
                  shiftwidth = 0;
                  tabstop = 2;
                };
                statusline = {
                  lualine = {
                    enable = true;
                  };
                };
                syntaxHighlighting = true;
                telescope = {
                  enable = true;
                };
                treesitter = {
                  enable = true;
                  autotagHtml = true;
                };
                viAlias = true;
                vimAlias = true;
                visuals = {
                  nvim-web-devicons = {
                    enable = true;
                  };
                  rainbow-delimiters = {
                    enable = true;
                  };
                };
              };
            };
          } config.my.home.nvf.overrides;
        };
      };
    };
}
