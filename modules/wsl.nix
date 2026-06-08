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
