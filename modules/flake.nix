{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-parts.flakeModules.modules
    inputs.git-hooks-nix.flakeModule
    (inputs.import-tree ../hosts)
  ];

  flake-file = {
    inputs = {
      eilmeldung = {
        url = lib.mkDefault "github:christo-auer/eilmeldung";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      flake-file = {
        url = lib.mkDefault "github:vic/flake-file";
      };
      flake-parts = {
        url = lib.mkDefault "github:hercules-ci/flake-parts";
        inputs.nixpkgs-lib.follows = "nixpkgs";
      };
      git-hooks-nix = {
        url = lib.mkDefault "github:cachix/git-hooks.nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      home-manager = {
        url = lib.mkDefault "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      import-tree = {
        url = lib.mkDefault "github:vic/import-tree";
      };
      nixos-wsl = {
        url = lib.mkDefault "github:nix-community/nixos-wsl";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      nixpkgs = {
        url = "github:nixos/nixpkgs/nixos-unstable";
      };
      nvf = {
        url = lib.mkDefault "github:notashelf/nvf";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      sops-nix = {
        url = lib.mkDefault "github:mic92/sops-nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  };

  perSystem =
    { config, pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = config.pre-commit.settings.enabledPackages;
          shellHook = config.pre-commit.shellHook;
        };
      };

      formatter = pkgs.nixfmt;

      pre-commit = {
        settings = {
          hooks = {
            deadnix = {
              enable = true;
            };
            nixfmt = {
              enable = true;
            };
            statix = {
              enable = true;
            };
          };
        };
      };
    };

  systems = [
    "x86_64-linux"
  ];
}
