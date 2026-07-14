{ lib, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;
      args = [
        "--prefer-output"
        "DP-3"
        "-W"
        "2560"
        "-H"
        "1440"
      ];
    };
    protontricks.enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steamcmd"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "xow_dongle-firmware"
    ];
  hardware.xone.enable = true;
}
