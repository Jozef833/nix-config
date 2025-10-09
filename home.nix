{
  inputs,
  osConfig,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  home = {
    packages = with pkgs; [
      eza
    ];
    shellAliases = {
      ls = "eza";
      tree = "eza -T";
    };
    inherit (osConfig.system) stateVersion;
  };

  programs = {
    bash = {
      enable = true;
    };

    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
      userEmail = "172046463+Jozef833@users.noreply.github.com";
      userName = "Jozef833";
    };

    nvf = {
      enable = true;
      defaultEditor = true;
      enableManpages = true;
      settings.vim = {
        autopairs.nvim-autopairs.enable = true;
        languages = {
          enableExtraDiagnostics = true;
          enableTreesitter = true;
          csharp.enable = true;
          css.enable = true;
          html.enable = true;
          lua.enable = true;
          markdown.enable = true;
          nix.enable = true;
          python.enable = true;
          rust.enable = true;
          sql.enable = true;
          ts.enable = true;
          yaml.enable = true;
        };
        lineNumberMode = "relative";
        lsp.enable = true;
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
        statusline.lualine.enable = true;
        syntaxHighlighting = true;
        telescope.enable = true;
        treesitter = {
          enable = true;
          autotagHtml = true;
        };
        viAlias = true;
        vimAlias = true;
        visuals = {
          nvim-web-devicons.enable = true;
          rainbow-delimiters.enable = true;
        };
      };
    };
  };
}
