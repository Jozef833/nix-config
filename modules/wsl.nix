_: {
  flake.modules.nixos.wsl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.nixos.wsl.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        environment = {
          sessionVariables = {
            # Force Mesa to use D3D12 Gallium driver (GPU via /dev/dxg) for general
            # OpenGL/EGL apps. This provides GPU-accelerated rendering for most programs.
            GALLIUM_DRIVER = "d3d12";
            # wsl.useWindowsDriver places libd3d12.so and libdxcore.so in /run/opengl-driver/lib,
            # but NixOS programs can't find them at runtime because the dynamic linker doesn't
            # search that path. Mesa's d3d12 Gallium driver needs these for GPU-accelerated
            # rendering via WSL GPU-PV (the /dev/dxg interface).
            LD_LIBRARY_PATH = "/run/opengl-driver/lib";
            MESA_LOADER_DRIVER_OVERRIDE = "d3d12";
          };
          systemPackages = with pkgs; [
            cifs-utils # CIFS/SMB mount support for network shares
            kmod # Provides modprobe/lsmod for kernel module management
            wget # Needed for VS Code WSL (along with nix-ld): https://nix-community.github.io/NixOS-WSL/how-to/vscode.html

            # WSL has no native xdg-open, and wslu (which used to provide wslview)
            # was discontinued and removed from nixpkgs. CLI tools that shell out
            # to `xdg-open` to launch browser-based logins (acli, kubectl
            # oidc-login, gcloud, etc.) fail with:
            #   exec: "xdg-open": executable file not found in $PATH
            #
            # We use PowerShell's Start-Process, passed the URL via WSLENV
            # rather than command-line interpolation, instead of the more
            # commonly suggested `cmd.exe /c start` or `explorer.exe`:
            #   - cmd.exe reinterprets `&` in the URL as a command separator,
            #     silently truncating OAuth URLs (which are full of
            #     `&`-separated query params).
            #   - explorer.exe is unreliable for handing URIs to the default
            #     browser; it sometimes just opens a plain Explorer window.
            # Routing the URL through an env var instead of the command line
            # sidesteps both cmd.exe's and PowerShell's quoting/escaping rules
            # entirely.
            (writeShellScriptBin "xdg-open" ''
              export WSLENV="OPEN_URL:$WSLENV"
              export OPEN_URL="$1"
              powershell.exe -NoProfile -NonInteractive -Command 'Start-Process $env:OPEN_URL' >/dev/null 2>&1
              exit 0
            '')
          ];
        };

        hardware = {
          graphics = {
            enable = true;
          };
        };

        programs = {
          # Needed for VS Code WSL (along with wget package): https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
          nix-ld = {
            enable = true;
          };
        };

        users = {
          users = {
            ${config.my.nixos.primaryUser} = {
              extraGroups = [
                "render"
                "video"
              ];
            };
          };
        };

        wsl = lib.recursiveUpdate {
          enable = true;
          defaultUser = config.my.nixos.primaryUser;
          useWindowsDriver = true;
        } config.my.nixos.wsl.overrides;
      };
    };
}
