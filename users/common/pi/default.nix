{ inputs, pkgs, ... }:
{
  imports = [ ./playwright.nix ];

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
