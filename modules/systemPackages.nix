{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vault"
    ];

  environment.systemPackages = with pkgs; [
    vault

    ltrace
    file
  ];

  programs.nix-ld.enable = true;
  programs.bcc.enable = true;
}
