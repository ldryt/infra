{ ... }:
let hidden = import ../secrets/obfuscated.nix;
in {
  services.caddy = {
    enable = true;
    email = hidden.ldryt.email;
  };
}
