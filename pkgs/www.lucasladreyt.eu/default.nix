{ pkgs, theme }:
pkgs.stdenv.mkDerivation {
  name = "lucasladreyt.eu";
  src = ./.;
  inherit theme;
  nativeBuildInputs = [ pkgs.hugo ];
  buildPhase = ''
    mkdir -p themes/PaperMod
    cp -r $theme/* themes/PaperMod
    hugo build --minify --destination public
  '';
  installPhase = ''
    mkdir -p $out
    cp -r public $out
  '';
}
