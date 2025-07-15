{
  config,
  hostname,
  lib,
  pkgs,
  stateVersion,
  system,
  username,
  ...
}:

{
  environment = {
    localBinInPath = true; # For uv

    shellInit = ''
      git config --global init.defaultBranch "main"
      git config --global user.email "172046463+Jozef833@users.noreply.github.com"
      git config --global user.name "Jozef833"
      if ! pgrep -u $USER ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)"
        ssh-add /home/${username}/.ssh/id_ed25519
        ssh-add /home/${username}/.ssh/id_rsa
      fi
    '';

    systemPackages = with pkgs; [
      iamb
      git
      nodejs_20
      python312
      tree
      uv

      (pkgs.writeShellScriptBin "python" ''
        export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
        exec ${pkgs.python312}/bin/python "$@"
      '')
    ];

    variables = {
      NEXT_TELEMETRY_DISABLED = "1"; # For Next.js (https://nextjs.org/telemetry)
      UV_PYTHON_DOWNLOADS = "never"; # For uv
    };
  };

  networking.nameservers = [
    "1.1.1.1"
  ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  nixpkgs.config.allowUnfree = true;

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

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
      ];
    };
  };

  system.stateVersion = stateVersion;

  wsl = {
    defaultUser = username;
    enable = true;
    wslConf.network.generateResolvConf = false;
  };
}

