{ pkgs, config, inputs, ... }: {
  imports = [
    ./hardware.nix

    ../../modules/gnome.nix
    ../../modules/resolved.nix
    ../../modules/intel-laptop.nix
    ../../modules/nix-gc.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_age_tinkerbell.key";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "ldryt" ];
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nixpkgs.config.allowUnfree = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "tinkerbell";
    networkmanager.enable = true;
    timeServers = [ "europe.pool.ntp.org" "time.cloudflare.com" ];
  };
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.wpa_supplicant.environment.OPENSSL_CONF =
    pkgs.writeText "openssl.cnf" ''
      openssl_conf = openssl_init
      [openssl_init]
      ssl_conf = ssl_sect
      [ssl_sect]
      system_default = system_default_sect
      [system_default_sect]
      Options = UnsafeLegacyRenegotiation
      [system_default_sect]
      CipherString = Default:@SECLEVEL=0
    '';

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

  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      hashedPasswordFile =
        config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };

  system.stateVersion = "23.05";
}
