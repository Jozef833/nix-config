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
      if ! pgrep -u $USER ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        ssh-add ~/.ssh/id_rsa
      fi
    '';

    systemPackages = with pkgs; [
      iamb
      nodejs_20
      python312
      tree
      uv

      #(pkgs.writeShellScriptBin "python" ''
      #  export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      #  exec ${pkgs.python312}/bin/python "$@"
      #'')
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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        acl
        attr
        bzip2
        curl
        libsodium
        libssh
        libxml2
        openssl
        stdenv.cc.cc
        systemd
        util-linux
        xz
        zlib
        zstd
      ];
    };
  };

  system.stateVersion = stateVersion;

  wsl = {
    enable = true;
    defaultUser = username;
    wslConf.network.generateResolvConf = false;
  };
}

