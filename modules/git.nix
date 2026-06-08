_: {
  flake.modules.homeManager.git =
    { config, lib, ... }:
    {
      options.my.home.git = {
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        signingKey = lib.mkOption {
          type = lib.types.str;
        };
        userEmail = lib.mkOption {
          type = lib.types.str;
        };
        userName = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = {
        programs = {
          git = lib.recursiveUpdate {
            enable = true;
            settings = {
              gpg = {
                format = "ssh";
                ssh = {
                  allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
                };
              };
              init = {
                defaultBranch = "main";
              };
              user = {
                email = config.my.home.git.userEmail;
                name = config.my.home.git.userName;
              };
            };
            signing = {
              key = config.my.home.git.signingKey;
              signByDefault = true;
            };
          } config.my.home.git.overrides;
        };
      };
    };
}
