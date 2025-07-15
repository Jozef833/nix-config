{
  inputs = {
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-24.11";
    };
    nixos-wsl = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/NixOS-WSL/release-24.11";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixos-wsl,
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
        nixos-wsl.nixosModules.default

        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit stateVersion system username;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = ./home.nix;
          };
        }
      ];

      specialArgs = {
        inherit hostname stateVersion system username;
      };

      system = system;
    };
  };
}
