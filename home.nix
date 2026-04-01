{
  config,
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
      nerd-fonts.jetbrains-mono
      ripgrep
      wl-clipboard
    ];
    file.".ssh/allowed_signers".text =
      "172046463+Jozef833@users.noreply.github.com "
      + builtins.readFile ./keys/ssh.pub;
    shellAliases = {
      lg = "lazygit";
      ls = "eza";
      tree = "eza -T";
    };
    inherit (osConfig.system) stateVersion;
  };

  programs = {
    bash = {
      enable = true;
    };

    claude-code = {
      enable = true;
      enableMcpIntegration = true;
      plugins = [ inputs.superpowers ];
      settings = {
        apiKeyHelper = "cat /run/secrets/anthropic-api-key";
        defaultMode = "acceptEdits";
        env = {
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
        };
        includeCoAuthoredBy = false;
        theme = "dark";
      };
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };

    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = false;
      };
      settings = {
        git_protocol = "ssh";
      };
    };

    gh-dash = {
      enable = true;
    };

    git = {
      enable = true;
      signing = {
        key = "/run/secrets/ssh-key";
        signByDefault = true;
      };
      settings = {
        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        };
        init.defaultBranch = "main";
        user = {
          email = "172046463+Jozef833@users.noreply.github.com";
          name = "Jozef833";
        };
      };
    };

    lazygit = {
      enable = true;
      settings = {
        disableStartupPopups = true;
        gui = {
          animateExplosion = false;
          nerdFontsVersion = "3";
          scrollHeight = 1;
          showRandomTip = false;
          statusPanelView = "allBranchesLog";
        };
        update = {
          method = "never";
        };
      };
    };

    librewolf = {
      enable = true;
    };

    mcp = {
      enable = true;
      servers = {
        atlassian = {
          disabled = true;
          url = "https://mcp.atlassian.com/v1/mcp";
        };
        azure = {
          disabled = true;
          args = [
            "server"
            "start"
          ];
          command = "${inputs.azure-mcp.packages.x86_64-linux.default}/bin/azmcp";
          env = {
            AZURE_MCP_COLLECT_TELEMETRY = "false";
          };
        };
        azure-devops = {
          disabled = true;
          args = [
            "onmilliman"
          ];
          command = "${inputs.azure-devops-mcp.packages.x86_64-linux.default}/bin/mcp-server-azuredevops";
        };
        github_grep = {
          disabled = true;
          url = "https://mcp.grep.app";
        };
        playwright = {
          disabled = true;
          command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        };
      };
    };

    nvf = {
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
          languages = {
            enableExtraDiagnostics = true;
            enableTreesitter = true;
            csharp = {
              enable = true;
            };
            css = {
              enable = true;
            };
            html = {
              enable = true;
            };
            lua = {
              enable = true;
            };
            markdown = {
              enable = true;
            };
            nix = {
              enable = true;
            };
            python = {
              enable = true;
            };
            rust = {
              enable = true;
            };
            sql = {
              enable = true;
            };
            ts = {
              enable = true;
            };
            yaml = {
              enable = true;
            };
          };
          lineNumberMode = "relative";
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
    };

    opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        plugin = [
          "superpowers@git+https://github.com/obra/superpowers.git#${inputs.superpowers.rev}"
        ];
      };
    };

    ssh = {
      enable = true;
      matchBlocks."github.com" = {
        identityFile = "/run/secrets/ssh-key";
        identitiesOnly = true;
      };
    };

    tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 0;
      keyMode = "vi";
      mouse = true;
      shortcut = "a";
    };
  };

}
