{ config, inputs, ... }: {
  imports = [
    ./hardware.nix
    ./sops.nix

    ../../modules/gnome.nix
    ../../modules/resolved.nix
    ../../modules/printing.nix
    ../../modules/intel-laptop.nix
    ../../modules/nixos-gc.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "tinkerbell";
  networking.networkmanager.enable = true;
  networking.useDHCP = false;

  time.timeZone = "Europe/Vilnius";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
  };
  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";

  users = {
    mutableUsers = false;
    users.ldryt = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "vboxusers" ];
      hashedPasswordFile =
        config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };

  virtualisation.virtualbox.host.enable = true;

  system.stateVersion = "23.05";
}
