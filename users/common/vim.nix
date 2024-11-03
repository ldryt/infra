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
      set background=dark
      colorscheme gruvbox
      let g:gruvbox_termcolors=16
      autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE

      filetype plugin indent on
      " show existing tab with 4 spaces width
      set tabstop=4
      " when indenting with '>', use 4 spaces width
      set shiftwidth=4
      " On pressing tab, insert 4 spaces
      set expandtab

      set nobackup   
      set number
      set colorcolumn=80
    '';
  };
}
