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
      git-credential-manager
      ripgrep
      wl-clipboard

      # WSL Hyprland launcher — sets the env vars needed before
      # Hyprland's EGL init (which happens before config loading).
      (writeShellScriptBin "hyprland-wsl" ''
        # Clean stale lock/socket from previous runs
        rm -f /mnt/wslg/runtime-dir/wayland-1.lock /mnt/wslg/runtime-dir/wayland-1 2>/dev/null

        exec env \
          WAYLAND_DISPLAY=wayland-0 \
          XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir \
          MESA_LOADER_DRIVER_OVERRIDE=kms_swrast \
          Hyprland "$@"
      '')
    ];
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
        defaultMode = "acceptEdits";
        env = {
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
        };
        includeCoAuthoredBy = false;
        theme = "dark-ansi";
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
        git_protocol = "https";
      };
    };

    gh-dash = {
      enable = true;
    };

    git = {
      enable = true;
      settings = {
        credential = {
          credentialStore = "gpg";
          helper = "manager";
          useHttpPath = true;
        };
        init = {
          defaultBranch = "main";
        };
        user = {
          email = "172046463+Jozef833@users.noreply.github.com";
          name = "Jozef833";
        };
      };
      signing = {
        signByDefault = true;
      };
    };

    gpg = {
      enable = true;
    };

    kitty = {
      enable = true;
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

    mcp = {
      enable = true;
      servers = {
        github = {
          url = "https://api.githubcopilot.com/mcp/insiders";
        };
        playwright = {
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
    };

    password-store = {
      enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 28800;
      maxCacheTtl = 28800;
      pinentry = {
        package = pkgs.pinentry-curses;
      };
    };

    pass-secret-service = {
      enable = true;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "ALT";
      "$terminal" = "kitty";

      # WSLg nested compositor environment
      #
      # NOTE: WAYLAND_DISPLAY and XDG_RUNTIME_DIR are NOT set here.
      # They are set when *launching* Hyprland (so Aquamarine finds WSLg).
      # Hyprland auto-sets WAYLAND_DISPLAY for child apps to its own
      # socket (wayland-1), so we must not override it to wayland-0.
      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "XCURSOR_SIZE,24"
        # Override Mesa driver so Hyprland can create an EGL context on
        # vgem's /dev/dri/renderD128. The system default (d3d12) cannot
        # initialize EGL on vgem. Child GUI apps (kitty, firefox, etc.)
        # will also use kms_swrast — acceptable since the real GPU is
        # used for Hyprland's compositing via the d3d12-backed EGL.
        "MESA_LOADER_DRIVER_OVERRIDE,kms_swrast"
        # kms_swrast EGL reports dmabuf format support but cannot
        # actually import cross-device dmabufs. Without this, Hyprland
        # advertises zwp_linux_dmabuf_v1 and clients (kitty, etc.) try
        # to present frames via dmabuf — which fails and kills them.
        # With this set, m_drmFormats stays empty, the protocol is not
        # advertised, and Mesa's Wayland EGL in clients falls back to
        # wl_shm buffer sharing automatically.
        "HYPRLAND_NO_DMABUF,1"
      ];

      # Monitor config for nested WSLg window.
      # WAYLAND-1 is the output name when running as a nested Wayland client.
      # WSLg's xdg_toplevel configure sends 0x0, so "preferred" resolves to
      # nothing. We must specify an explicit resolution.
      monitor = "WAYLAND-1, 1280x720@60, 0x0, 1";

      general = {
        border_size = 2;
        gaps_in = 4;
        gaps_out = 8;
        "col.active_border" = "rgba(88c0d0ff) rgba(81a1c1ff) 45deg";
        "col.inactive_border" = "rgba(3b4252ff)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 6;
        shadow = {
          enabled = false;
        };
        blur = {
          enabled = false;
        };
      };

      # Disable animations for better performance in nested/WSL mode
      animations = {
        enabled = false;
      };

      input = {
        follow_mouse = 1;
        sensitivity = 0;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      debug = {
        disable_logs = false;
      };

      # Keybindings
      bind = [
        # Core
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, Q, killactive,"
        "$mod SHIFT, E, exit,"

        # Window focus (vim keys)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move windows
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # Layout
        "$mod, V, togglesplit,"
        "$mod, F, fullscreen, 0"
        "$mod, P, pseudo,"
        "$mod, Space, togglefloating,"
      ];

      # Resize with mod + right mouse drag
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
