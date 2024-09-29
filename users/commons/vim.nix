{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox
      gitgutter
    ];
    extraConfig = ''
      set nobackup   
      set autoindent
      set number
      set colorcolumn=80
    '';
  };
}
