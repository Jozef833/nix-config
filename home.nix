{
  config,
  pkgs,
  stateVersion,
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

    stateVersion = stateVersion;
  };

  programs = {
    neovim = {
      enable = true;
      extraConfig = ''
        au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
        set autoindent
        set expandtab
        set mouse=a
	set mousescroll=ver:1
        set number
        set relativenumber
        set shiftwidth=2
        set smartindent
        set smarttab
        set tabstop=2
        syntax on
      '';
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
      lfs.enable = true;
      userEmail = "Jozef.Porubcin@onmilliman.com";
      userName = "Jozef Porubcin";
    };
  };
}
