# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    <nixos-wsl/modules>
  ];

  environment = {
    localBinInPath = true; # For uv

    shellInit = ''
      git config --global init.defaultBranch "main"
      git config --global user.email "172046463+Jozef833@users.noreply.github.com"
      git config --global user.name "Jozef833"
      if ! pgrep -u $USER ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)"
        ssh-add /home/nixos/.ssh/id_ed25519
        ssh-add /home/nixos/.ssh/id_rsa
      fi
    '';

    systemPackages = with pkgs; [
      git
      nodejs_20
      python312
      tree
      uv
    ];

    variables = {
      NEXT_TELEMETRY_DISABLED = "1"; # For Next.js (https://nextjs.org/telemetry)
      UV_PYTHON_DOWNLOADS = "never"; # For uv
    };
  };

  networking.nameservers = [
    "1.1.1.1"
  ];

  programs = {
    neovim = {
      configure = {
        customRC = ''
          au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
          set autoindent
          set expandtab
          set mouse=a
          set number
          set relativenumber
          set shiftwidth=2
          set smartindent
          set smarttab
          set tabstop=2
          syntax on
        '';
      };
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  wsl = {
    defaultUser = "nixos";
    enable = true;
    wslConf.network.generateResolvConf = false;
  };
}

