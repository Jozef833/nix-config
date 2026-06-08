{ lib, ... }:
{
  options = {
    hosts = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.lazyAttrsOf (
          lib.types.submodule {
            options = {
              modules = lib.mkOption { type = lib.types.listOf lib.types.deferredModule; };
              system = lib.mkOption { type = lib.types.str; };
            };
          }
        )
      );
      default = { };
    };
  };
}
