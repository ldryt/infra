{ config, lib, ... }:
let
  cfg = config.ldryt-infra.persist;
in
{
  options.ldryt-infra.persist = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
    };
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
    };
    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            directories = lib.mkOption {
              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
              default = [ ];
            };
            files = lib.mkOption {
              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
              default = [ ];
            };
          };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    ldryt-infra.persist.directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/containers"
      "/var/lib/acme"
    ];

    ldryt-infra.persist.files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];

    environment.persistence = {
      ${cfg.path} = {
        hideMounts = true;
        directories = lib.unique cfg.directories;
        files = lib.unique cfg.files;
        inherit (cfg) users;
      };
      "/nix/tmp".directories = [
        "/tmp"
        "/var/tmp"
        "/var/cache"
      ];
    };
  };
}
