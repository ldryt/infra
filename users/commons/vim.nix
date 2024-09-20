{ ... }:
{
  programs.vim.enable = true;
  programs.vim = {
    extraConfig = ''
         set autoindent
         set number
         set colorcolumn=80
         " Jump to the last position when reopening a file
         if has("autocmd")
           au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
      \| exe "normal! g'\"" | endif
         endif
    '';
  };
}
