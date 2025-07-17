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

    neovim = {
      enable = true;
      defaultEditor = true;
      extraConfig = ''
        au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
        set autoindent
        set expandtab
        set mouse=a
        set number
        set relativenumber
        set shiftwidth=2
        set smartindent
        set smarttab
        set tabstop=2
        syntax on
      '';
      viAlias = true;
      vimAlias = true;
    };
  };
}
