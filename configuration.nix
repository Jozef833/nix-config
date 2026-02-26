{
  lib,
  pkgs,
  stateVersion,
  username,
  ...
}:

{
  environment = {
    systemPackages = with pkgs; [
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

  users = {
    users = {
      ${username} = {
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
  };
}
