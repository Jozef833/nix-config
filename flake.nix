{
  inputs = {
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-25.05";
    };
    nixos-wsl = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/NixOS-WSL/release-25.05";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    nvf = {
      url = "github:NotAShelf/nvf/dde524f7cc4b9e56cf45223a23e1b598f68848d7";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nvf,
    nixos-wsl,
    ...
  } @ inputs:
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

        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = ./home.nix;
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
