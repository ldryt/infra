{ config, pkgs, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;
  hardware.enableRedistributableFirmware = true;

  # fix the following error :
  # modprobe: FATAL: Module ahci not found in directory
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  services.journald.console = "/dev/tty1";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/nix/sops_age_printer.key";
  };

  system.stateVersion = "24.11";

  services.klipper = {
    enable = true;
    user = config.services.moonraker.user;
    group = config.services.moonraker.group;
    configFile = ./VORON0.2_SKR_PICO_V1.0.cfg;
    mutableConfig = true;
    logFile = config.services.moonraker.stateDir + "/logs/klippy.log";
  };

  security.polkit.enable = true;
  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    settings = {
      authorization = {
        trusted_clients = [
          "0.0.0.0/0"
        ];
        cors_domains = [
          "https://printer.ldryt.dev"
        ];
      };
    };
  };

  networking.firewall.interfaces."printertunnel".allowedTCPPorts = [ 80 9999 ];
  services.mainsail.enable = true;

  services.ustreamer = {
    enable = true;
    listenAddress = "0.0.0.0:9999";
    extraArgs = [
      "--resolution=1024x768"
      "--format=jpeg"
      "--quality=72"

      "--image-default"
      "--sharpness=80"
      "--brightness=55"
      "--contrast=5"
      "--saturation=5"

      "--buffers=3"
      "--device-timeout=5"
    ];
  };
}
