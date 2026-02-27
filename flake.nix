{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager";
    };
    nixos-wsl = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/nixos-wsl";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nvf = {
      url = "github:notashelf/nvf";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nvf,
    nixos-wsl,
    ...
  }:
  let
    hostname = "nixos";
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    stateVersion = "25.05"; # Did you read the comment?
    system = "x86_64-linux";
    username = "nixos";
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      modules = [
        nixos-wsl.nixosModules.default

        # Overlays: patch aquamarine + hyprland for WSLg compatibility
        {
          nixpkgs.overlays = [
            (final: prev: {
              aquamarine = prev.aquamarine.overrideAttrs (old: {
                patches = (old.patches or []) ++ [ ./patches/aquamarine-wsl-shm.patch ];
              });
              hyprland = prev.hyprland.overrideAttrs (old: {
                patches = (old.patches or []) ++ [ ./patches/hyprland-wsl-renderbuffer.patch ];
              });
            })
          ];
        }

        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users = {
              ${username} = ./home.nix;
            };
          };
        }
      ];

      specialArgs = {
        inherit hostname inputs stateVersion username;
      };

      system = system;
    };
  };
}
