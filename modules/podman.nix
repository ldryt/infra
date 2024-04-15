{ pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--volumes"
        ];
      };
    };
    oci-containers.backend = "podman";
  };

  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui
  ];
}
