{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-24.11";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  }:
  let
    hostname = "nixos";
    stateVersion = "24.11";
    system = "x86_64-linux";
    username = "nixos";
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = ./home.nix;
          };

          extraSpecialArgs = {
            inherit stateVersion system username;
          };
        }
      ];

      specialArgs = {
        inherit hostname stateVersion system username;
      };
    };
  };
}
