{ ... }: {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than +10";
  };
  nix.settings.auto-optimise-store = true;
}
