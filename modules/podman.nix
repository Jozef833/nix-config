_: {
  flake.modules.nixos.podman =
    { config, lib, ... }:
    {
      options.my.nixos.podman.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        virtualisation = lib.recursiveUpdate {
          containers = {
            containersConf = {
              settings = {
                containers = {
                  log_driver = "json-file";
                };
                engine = {
                  cgroup_manager = "cgroupfs";
                  events_logger = "file";
                };
              };
            };
          };
          podman = {
            enable = true;
          };
        } config.my.nixos.podman.overrides;
      };
    };
}
