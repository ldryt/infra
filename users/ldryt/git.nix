{ ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  programs.git = {
    enable = true;
    userName = "${hidden.ldryt.name} ${hidden.ldryt.surname}";
    userEmail = hidden.ldryt.email;
  };
}
