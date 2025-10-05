{
  config,
  hostname,
  lib,
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

  wsl = {
    enable = true;
    defaultUser = username;
  };
}
