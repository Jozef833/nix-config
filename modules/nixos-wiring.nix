{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations = lib.mapAttrs (
      _: hostCfg:
      inputs.nixpkgs.lib.nixosSystem {
        inherit (hostCfg) modules system;
        specialArgs = {
          inherit inputs;
        };
      }
    ) (config.hosts.nixos or { });
  };
}
