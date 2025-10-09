{
  pkgs,
  stateVersion,
  username,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    coreutils
    shadow
    gnupg
    bash
  ];

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
  };

  nixpkgs.config.allowUnfree = false;

  programs = {
    gnupg = {
      agent.enable = true;
    };

    ssh = {
      startAgent = true;
    };
  };

  security.pki.certificateFiles = [
    ./ZscalerRootCertificate-2048-SHA256-Feb2025.crt
  ];

  system.stateVersion = stateVersion;

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
