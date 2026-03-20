{
  lib,
  pkgs,
  stateVersion,
  username,
  ...
}:

{
  environment = {
    sessionVariables = {
      # wsl.useWindowsDriver places libd3d12.so and libdxcore.so in /run/opengl-driver/lib,
      # but NixOS programs can't find them at runtime because the dynamic linker doesn't
      # search that path. Mesa's d3d12 Gallium driver needs these for GPU-accelerated
      # rendering via WSL GPU-PV (the /dev/dxg interface).
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      # Force Mesa to use D3D12 Gallium driver (GPU via /dev/dxg) for general
      # OpenGL/EGL apps. This provides GPU-accelerated rendering for most programs.
      GALLIUM_DRIVER = "d3d12";
      MESA_LOADER_DRIVER_OVERRIDE = "d3d12";
    };
    systemPackages = with pkgs; [
      cifs-utils  # CIFS/SMB mount support for network shares
      kmod  # Provides modprobe/lsmod for kernel module management
      wget  # Needed for VS Code WSL (along with nix-ld): https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
    ];
  };

  hardware = {
    graphics = {
      enable = true;
    };
  };

  # O: drive — \\milw-isilon-prod-smb.milliman.com\milwh-users$\Jozef.Porubcin
  fileSystems."/mnt/network/Jozef.Porubcinai/milwh-users$/Jozef.Porubcin" = {
    device = "//milw-isilon-prod-smb.milliman.com/milwh-users$/Jozef.Porubcin";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials-Jozef.Porubcinai"
      "domain=milliman.com"
      "uid=1000"
      "gid=100"
      "file_mode=0664"
      "dir_mode=0775"
      "nofail"                    # don't block boot if share is unreachable
      "x-systemd.automount"       # mount on first access, not at boot
      "x-systemd.idle-timeout=60"
    ];
  };

  # T: drive — \\milw-isilon-prod-smb.milliman.com\milwh-docs$
  fileSystems."/mnt/network/Jozef.Porubcinai/milwh-docs$" = {
    device = "//milw-isilon-prod-smb.milliman.com/milwh-docs$";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials-Jozef.Porubcinai"
      "domain=milliman.com"
      "uid=1000"
      "gid=100"
      "file_mode=0664"
      "dir_mode=0775"
      "nofail"                    # don't block boot if share is unreachable
      "x-systemd.automount"       # mount on first access, not at boot
      "x-systemd.idle-timeout=60"
    ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      dates = "weekly";
    };
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
    # Needed for VS Code WSL (along with wget package): https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
    nix-ld = {
      enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
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

  users = {
    users = {
      ${username} = {
        extraGroups = [ 
          "render"
          "video"
        ];
        shell = pkgs.bash;
        useDefaultShell = true;
      };
    };
  };

  virtualisation = {
    containers.containersConf.settings = {
      engine = {
        cgroup_manager = "cgroupfs";
        events_logger = "file";
      };
    };
    podman = {
      enable = true;
    };
  };

  wsl = {
    enable = true;
    defaultUser = username;
    useWindowsDriver = true;
  };
}
