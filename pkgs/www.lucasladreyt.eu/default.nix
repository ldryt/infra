{ pkgs }:
pkgs.stdenv.mkDerivation {
  name = "lucasladreyt.eu";
  src = ./.;
  theme = pkgs.fetchFromGitHub {
    owner = "adityatelange";
    repo = "hugo-PaperMod";
    rev = "7d061d56d4664bd9c8241eb904994c98b928f0c8";
    sha256 = "sha256-+OyrkV+9TELJOoz1qL63Ad95jobRQfv6RpoHKhemDfM=";
  };
  nativeBuildInputs = [ pkgs.hugo ];
  buildPhase = ''
    mkdir -p themes/PaperMod
    cp -r $theme/* themes/PaperMod
    hugo --minify --destination public
    find
  '';
  installPhase = ''
    mkdir -p $out
    cp -r public $out
  '';
}
