{
  config,
  pkgs,
  stateVersion,
  system,
  username,
  ...
}:

{
  home = {
    file.".config/iamb/config.toml".text = ''
      default_profile = "octoclonius"

      [profiles.octoclonius]
      user_id = "@octoclonius:matrix.org"

      [settings]
      image_preview = {}
    '';

    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
    username = username;
  };

  programs = {
    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
      userEmail = "Jozef.Porubcin@onmilliman.com";
      userName = "Jozef Porubcin";
    };
  };
}
