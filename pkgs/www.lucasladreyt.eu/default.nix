{ pkgs }:
pkgs.stdenv.mkDerivation {
  name = "lucasladreyt.eu";
  src = ./.;
  theme = pkgs.fetchFromGitHub {
    owner = "adityatelange";
    repo = "hugo-PaperMod";
    # renovate: datasource=git-refs depName=https://github.com/adityatelange/hugo-PaperMod currentValue=master
    rev = "d3768854d00ad003b0a8dbdba254ce9224377a01";
    sha256 = "sha256-KMnp97r0EDF7R47LpeSBkEyo+Ls6KO73esK/S8TurIo=";
  };
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
