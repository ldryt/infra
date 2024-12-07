{ lib, pkgs, ... }:
{
  programs.steam.enable = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steamcmd"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
    ];

  environment.systemPackages = with pkgs; [
    steamcmd
    steam-tui
  ];
}
