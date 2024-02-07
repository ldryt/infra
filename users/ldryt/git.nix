{ ... }:
# beware: this "semi-secrets" handling method is exposing those to the nix store with full access to all users. this is fine for my use case, but you should be careful.
let secrets = import ../../secrets/git-crypt.nix;
in
{
  programs.git = {
    enable = true;
    userName = secrets.ldryt.name + " " + secrets.ldryt.surname;
    userEmail = secrets.ldryt.email;
  };
}
