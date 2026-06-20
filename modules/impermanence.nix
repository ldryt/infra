{ config, lib, ... }:
let
  cfg = config.ldryt-infra.persist;
  cmp =
    name: a: b:
    (if builtins.isString a then a else a."${name}") < (if builtins.isString b then b else b."${name}");
  cmpDir = a: b: cmp "directory" a b;
  cmpFile = a: b: cmp "file" a b;
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
        directories = lib.unique (lib.sort cmpDir cfg.directories);
        files = lib.unique (lib.sort cmpFile cfg.files);
        users = lib.mapAttrs (_: u: {
          directories = lib.unique (lib.sort cmpDir u.directories);
          files = lib.unique (lib.sort cmpFile u.files);
        }) cfg.users;
      };
      "/nix/tmp".directories = [
        "/tmp"
        "/var/tmp"
        "/var/cache"
      ];
    };
  };
}
