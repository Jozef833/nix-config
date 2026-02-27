{
  lib,
  pkgs,
  stateVersion,
  username,
  ...
}:

{
  # Load vgem kernel module to create /dev/dri/renderD128.
  # WSL2's dxgkrnl never creates DRM render nodes; vgem (Virtual GEM provider)
  # provides GEM operations that satisfy GBM allocator requirements.
  # The module exists in the stock WSL kernel at:
  #   /lib/modules/*/kernel/drivers/gpu/drm/vgem/vgem.ko
  boot.kernelModules = [ "vgem" ];

  environment = {
    sessionVariables = {
      # wsl.useWindowsDriver places libd3d12.so and libdxcore.so in /run/opengl-driver/lib,
      # but NixOS programs can't find them at runtime because the dynamic linker doesn't
      # search that path. Mesa's d3d12 Gallium driver needs these for GPU-accelerated
      # rendering via WSL GPU-PV (the /dev/dxg interface).
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      # Force Mesa to use D3D12 Gallium driver (GPU via /dev/dxg) for general
      # OpenGL/EGL apps. This provides GPU-accelerated rendering for most programs.
      # Hyprland itself overrides this to kms_swrast (see home.nix) because its
      # EGL context is created on vgem's /dev/dri/renderD128 which has no d3d12
      # DRI driver — only kms_swrast can create an EGL screen on vgem.
      GALLIUM_DRIVER = "d3d12";
      MESA_LOADER_DRIVER_OVERRIDE = "d3d12";
      # WSLg places the Wayland socket at /mnt/wslg/runtime-dir/wayland-0,
      # not the standard /run/user/<uid>/. Hyprland's Aquamarine backend
      # uses WAYLAND_DISPLAY + XDG_RUNTIME_DIR to find the parent compositor.
      XDG_RUNTIME_DIR = "/mnt/wslg/runtime-dir";
    };
    systemPackages = with pkgs; [
      kmod  # Provides modprobe/lsmod for kernel module management
      wget
    ];
  };

  hardware = {
    graphics = {
      enable = true;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
      ];
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = false;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "claude-code"
      ];
    };
  };

  programs = {
    hyprland = {
      enable = true;
    };
    # Used for VS Code WSL (along with wget package): https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
    nix-ld = {
      enable = true;
    };
  };

  security = {
    pki = {
      certificateFiles = [
        ./ZscalerRootCertificate-2048-SHA256-Feb2025.crt
      ];
    };
  };

  system = {
    stateVersion = stateVersion;
  };

  # Make /dev/dri/card0 (vgem primary node) accessible to the video group.
  # WSL2 creates it with group 39 (not mapped to any NixOS group).
  # The DRM dumb buffer allocator requires the primary node for buffer
  # allocation — the render node (renderD128) doesn't support dumb buffers.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", MODE="0666"
  '';

  users = {
    users = {
      ${username} = {
        extraGroups = [ "video" "render" ];
        shell = pkgs.bash;
        useDefaultShell = true;
      };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
    };
  };

  wsl = {
    enable = true;
    defaultUser = username;
    docker-desktop = {
      enable = true;
    };
    useWindowsDriver = true;
  };
}
