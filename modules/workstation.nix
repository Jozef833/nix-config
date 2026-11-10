{ config, ... }:
{
  flake.modules.nixos.workstation = {
    home-manager.sharedModules = [ config.flake.modules.homeManager.workstation ];
  };
}
