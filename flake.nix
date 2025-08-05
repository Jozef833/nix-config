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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
              inherit stateVersion;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = ./home.nix;
          };
        }
      ];

      specialArgs = {
        inherit hostname stateVersion username;
      };

      system = system;
    };
  };
}
