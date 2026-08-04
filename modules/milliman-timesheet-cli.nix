_: {
  flake.modules.homeManager.milliman-timesheet-cli =
    { inputs, pkgs, ... }:
    {
      home.packages = [
        (pkgs.callPackage "${inputs.milliman-timesheet-cli}/nix/package.nix" { })
      ];
    };
}
