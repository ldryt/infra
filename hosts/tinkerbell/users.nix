{
  inputs,
  config,
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
      ldryt = import ../../users/ldryt;
    };
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit inputs;
      inherit pkgs-unstable;
      inherit pkgs-master;
      firefox-addons = inputs.firefox-addons;
    };
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
      ".local/state/syncthing"
      ".ssh"
      ".local/share/direnv"
      ".local/share/wluma"
      ".config/SuperSlicer"
      ".mozilla"
      ".thunderbird"
      ".terraform.d"
      ".config/dconf"
      ".local/share/Steam"
      ".config/JetBrains"
      ".config/keepassxc"
      ".cache/keepassxc"
      ".config/obsidian"
      ".parsec"
      ".parsec-persistent"
      ".local/share/TelegramDesktop"
      ".local/share/PrismLauncher"
      ".config/Slack"
      ".gnupg"
      "STM32Cube"
      "STM32CubeIDE"
      ".stm32cubemx"
      ".stmcube"
      ".stmcufinder"
      ".vagrant.d"
      ".config/zen"
    ];
    files = [
      ".config/digikamrc"
      ".config/digikam_systemrc"
    ];
  };
}
