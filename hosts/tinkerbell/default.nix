{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware.nix

    ../../modules/podman.nix
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_age_tinkerbell.key";

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      settings = {
        connection.ipv6.ip6-privacy = 2;
        connection-mac-randomization.wifi.cloned-mac-address = "stable";
      };
      dns = "systemd-resolved";
    };
    timeServers = [
      "europe.pool.ntp.org"
      "time.cloudflare.com"
    ];
    nameservers = [
      "2606:4700:4700::1111#cloudflare-dns.com"
      "2606:4700:4700::1001#cloudflare-dns.com"
      "1.1.1.1#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
    ];
  };
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  time.timeZone = "Europe/Paris";
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

  virtualisation.virtualbox.host.enable = true;

  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "vboxusers"
        "libvirtd"
      ];
      hashedPasswordFile = config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];

  # GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = with pkgs; [
    cheese
    epiphany
    yelp
    file-roller
    geary
    seahorse
    gnome-font-viewer
    gnome-system-monitor
    gnome-characters
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-tour
  ];

  # Battery savings
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      PLATFORM_PROFILE_ON_AC = "quiet";
      PLATFORM_PROFILE_ON_BAT = "quiet";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      CPU_MAX_PERF_ON_AC = 100;
      CPU_MAX_PERF_ON_BAT = 80;
    };
  };

  services.logind = {
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
    lidSwitch = config.services.logind.powerKey;
    lidSwitchDocked = "ignore";
  };

  system.stateVersion = "23.05";
}
