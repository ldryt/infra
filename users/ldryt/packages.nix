{ pkgs, ... }:
{
  imports = [ ../common/packages/cli.nix ];

  home.packages = with pkgs; [
    nix-tree
    wl-clipboard
    vesktop
    super-slicer-beta
    evolution
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
