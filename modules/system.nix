{ inputs, ... }:
let
  rev = inputs.self.rev or inputs.self.dirtyRev or null;
in
{
  flake.modules.generic.system = {
    system = {
      configurationRevision = rev;
    };
  };
}
