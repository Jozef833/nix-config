{
  pkgs,
  stateVersion,
  username,
  ...
}:

{
  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
  };

  nixpkgs.config.allowUnfree = false;

  security.pki.certificateFiles = [
    ./ZscalerRootCertificate-2048-SHA256-Feb2025.crt
  ];

  system.stateVersion = stateVersion;

  users.users.${username} = {
    shell = pkgs.bash;
    useDefaultShell = true;
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
