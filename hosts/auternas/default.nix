{ inputs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    ./disk-config.nix
    ./mc.nix

    ../../modules/openssh.nix
    ../../modules/fail2ban.nix
    ../../modules/nixos-gc.nix
    ../../modules/podman.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" ];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "auternas";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
    interfaces."enp7s0".useDHCP = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOeroOCZerWNky5qXwi0uPV7+bOXHETDfXui0zc8fErp ldryt@tinkerbell"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7H3QrvcjOTte+AfpDQC2Rc0RfgXv6xXqed7DUOXU9O colon@kiwi"
  ];

  system.stateVersion = "23.11";
}
