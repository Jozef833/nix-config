{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

{
  imports = [
    inputs.charmbracelet.homeModules.crush
    inputs.nvf.homeManagerModules.default
  ];

  home = {
    packages = with pkgs; [
      eza
      nerd-fonts.jetbrains-mono
      postman
      ripgrep
      wl-clipboard
    ];
    file.".ssh/allowed_signers".text =
      "172046463+Jozef833@users.noreply.github.com " + builtins.readFile ./keys/ssh-github.pub;
    sessionVariables = {
      OPENCODE_EXPERIMENTAL = true;
    };
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

    crush = {
      #enable = true;
      settings = {
        mcp = lib.mapAttrs (_name: srv: {
          disabled = srv.disabled or false;
          args = srv.args or null;
          command = srv.command or null;
          type = if srv ? url && srv.url != null then "http" else "stdio";
          url = srv.url or null;
        }) config.programs.mcp.servers;
        options = {
          attribution = {
            generated_with = false;
            trailer_style = "none";
          };
          disable_metrics = true;
          disabled_skills = [
            "crush-config"
            "crush-hooks"
            "jq"
          ];
        };
        providers = {
          anthropic = {
            api_key = "$(cat /run/secrets/anthropic-api-key)";
            models = [ ];
          };
        };
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

    git = {
      enable = true;
      signing = {
        key = "/run/secrets/ssh-github";
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
        azure-devops = {
          disabled = true;
          args = [
            "onmilliman"
          ];
          command = "${inputs.azure-devops-mcp.packages.x86_64-linux.default}/bin/mcp-server-azuredevops";
        };
        exa = {
          disabled = true;
          url = "https://mcp.exa.ai/mcp";
        };
        github_grep = {
          disabled = true;
          url = "https://mcp.grep.app";
        };
        playwright = {
          disabled = true;
          args = [
            "--isolated"
          ];
          command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
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
            typescript = {
              enable = true;
            };
            yaml = {
              enable = true;
            };
          };
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
    };

    opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        autoupdate = false;
        lsp = true;
        plugin = [
          "superpowers@git+https://github.com/obra/superpowers.git#${inputs.superpowers.rev}"
        ];
        provider = {
          anthropic = {
            options = {
              apiKey = "{file:/run/secrets/anthropic-api-key}";
            };
          };
        };
        share = "disabled";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/ssh-github";
        };
        "ssh.dev.azure.com" = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = true;
          IdentityFile = "/run/secrets/ssh-azure-devops";
        };
      };
    };
  };

  services = {
    ssh-agent = {
      enable = true;
    };
  };
}
