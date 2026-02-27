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
    aquamarine-wsl = {
      url = "git+file:///home/nixos/Documents/personal/repositories/aquamarine?ref=wsl-shm-fallback";
      flake = false;
    };
    hyprland-wsl = {
      url = "git+file:///home/nixos/Documents/personal/repositories/hyprland?ref=wsl-shm-fallback&submodules=1";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nvf,
    nixos-wsl,
    aquamarine-wsl,
    hyprland-wsl,
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

        # Overlays: use local forks of aquamarine + hyprland with WSLg fixes
        {
          nixpkgs.overlays = [
            (final: prev: {
              aquamarine = prev.aquamarine.overrideAttrs (old: {
                src = aquamarine-wsl;
                patches = [];
              });
              hyprland = prev.hyprland.overrideAttrs (old: {
                src = hyprland-wsl;
                patches = [];
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
