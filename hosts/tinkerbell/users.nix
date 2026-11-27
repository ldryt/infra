{
  inputs,
  config,
  lib,
  pkgs-unstable,
  pkgs-master,
  ...
}:
{
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ldryt.imports = [
        ../../users/ldryt
        ../../users/ldryt/desktop.nix
      ];
    };
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit inputs;
      inherit pkgs-unstable;
      inherit pkgs-master;
      firefox-addons = inputs.firefox-addons;
    };
  };

  # start GDM in parallel
  systemd.services.home-manager-ldryt.before = lib.mkForce [ "user@1000.service" ];
  systemd.services."user@1000" = {
    overrideStrategy = "asDropin";
    requires = [ "home-manager-ldryt.service" ];
  };

  sops.secrets."pi/searx/password" = {
    owner = "ldryt";
    mode = "0400";
  };
  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.ldryt = {
      description = "Lucas Ladreyt";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "disk"
        "vboxusers"
        "docker"
      ];
      hashedPasswordFile = config.sops.secrets."users/ldryt/hashedPassword".path;
    };
  };
  nix.settings.trusted-users = [ config.users.users.ldryt.name ];

  ldryt-infra.persist.users.ldryt = {
    directories = [
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
      "Sync"
      ".ssh"
      ".local/state"
      ".local/share"
      ".config"
      ".thunderbird"
      ".terraform.d"
      ".cache"
      ".parsec"
      ".parsec-persistent"
      ".gnupg"
      {
        directory = ".pi/agent";
        mode = "0700";
      }
      "STM32Cube"
      "STM32CubeIDE"
      ".stm32cubemx"
      ".stmcube"
      ".stmcufinder"
      ".vagrant.d"
    ];
  };
}
