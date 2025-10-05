{
  config,
  pkgs,
  stateVersion,
  ...
}:

{
  home = {
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
      userEmail = "172046463+Jozef833@users.noreply.github.com";
      userName = "Jozef833";
    };
  };
}
