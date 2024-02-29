{ config, pkgs, lib, ... }:
let
  hidden = import ../../../secrets/obfuscated.nix;
  auternasInternalIP = "10.0.0.3";
  auternasServerName = "Auternas";
  terraformConfigName = "auternas-deploy";
  velocitySubdomain = "auternas";
  velocityJar = pkgs.fetchurl {
    url =
      "https://api.papermc.io/v2/projects/velocity/versions/3.3.0-SNAPSHOT/builds/363/downloads/velocity-3.3.0-SNAPSHOT-363.jar";
    sha256 = "a5f958608eb890fa12dc16c492fa06122a0219c6696a1f17f405b972fce2dd00";
  };
in {
  virtualisation.oci-containers.containers = {
    "velocity" = {
      image =
        "docker.io/library/eclipse-temurin:21-jdk@sha256:b1a93e74b7ebce1735d119a45ea17b3cddddfd115a820cde8422b0597e1b5bc9";
      entrypoint = "java";
      cmd = [
        "-Xms128M"
        "-Xmx128M"
        "-XX:+UseG1GC"
        "-XX:G1HeapRegionSize=4M"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+ParallelRefProcEnabled"
        "-XX:+AlwaysPreTouch"
        "-XX:MaxInlineLevel=15"
        "-jar"
        "velocity.jar"
      ];
      ports = [ "0.0.0.0:25565:25577" ];
      volumes = [
        "/etc/velocity.toml:/velocity.toml:ro"
        "${velocityJar}:/velocity.jar:ro"
        "${
          config.sops.secrets."services/velocity/forwardingSecret".path
        }:/velocity.secret:ro"
        "/dev/null:/plugins/bStats/config.txt"
      ];
    };
  };

  # needed for terraform to init itself
  systemd.tmpfiles.rules =
    [ "d /etc/${terraformConfigName} 0744 ${config.users.users.colon.name}" ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "terraform" ];
  systemd.services.${terraformConfigName} = {
    description = "Automated mc server deployment daemon";
    wantedBy = [ "multi-user.target" ];
    after =
      [ "${config.virtualisation.oci-containers.backend}-velocity.service" ];
    serviceConfig = {
      Restart = "always";
      User = config.users.users.colon.name;
    };
    path = [
      # (pkgs.terraform.withPlugins (p: [ p.null p.external p.hcloud ]))
      pkgs.terraform
      pkgs.git
      pkgs.bash
      pkgs.jq
      pkgs.nix
    ];
    script = ''
      #!/usr/bin/env bash

      set -euo pipefail

      terraform -chdir=/etc/${terraformConfigName} init -input=false
      terraform -chdir=/etc/${terraformConfigName} plan -input=false

      while true; do
        echo "Entered main loop"
        journalctl -fu ${config.virtualisation.oci-containers.backend}-velocity.service --since "0sec ago" | while read -r line; do
          if echo "$line" | grep -q "Unable to connect you to ${auternasServerName}. Please try again later."; then
            echo "Detected a connection attempt."
            echo "Deploying with terraform..."
            terraform -chdir=/etc/${terraformConfigName} apply -auto-approve -lock=false -input=false
            echo "Deployed with terraform"
            break
          fi
        done
        echo "Exited main loop"
       
      done
    '';
  };

  environment.etc = {
    "${terraformConfigName}/providers.tf".text = ''
      terraform {
        required_providers {
          hcloud = {
            source = "hetznercloud/hcloud"
            version = "1.45.0"
          }
        }
      }

      provider "hcloud" {
        # this token is revoked by now ;)
        token = "gHDkiqB4yNX3YmVvKncVBFMyJ27bdLaNRqn7atZJeWPbDwBCiwbaSTweFrNqwY9Q"
      }
    '';

    "${terraformConfigName}/main.tf".text = ''
      data "hcloud_network" "velocity_network" {
        name = "velocity-network"
      }
      resource "hcloud_ssh_key" "auternas_key" {
        name = "auternas-key"
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOeroOCZerWNky5qXwi0uPV7+bOXHETDfXui0zc8fErp"
      }
      data "hcloud_image" "auternas-snapshot" {
        id = 444444444
      }
      resource "hcloud_server" "auternas_server" {
        depends_on = [ hcloud_ssh_key.auternas_key ]
        name = "auternas"
        image = data.hcloud_image.auternas-snapshot.id
        server_type = "ccx13"
        datacenter = "fsn1-dc14"
        ssh_keys = [ hcloud_ssh_key.auternas_key.id ]
        network {
          network_id = data.hcloud_network.velocity_network.id
          ip = "${auternasInternalIP}"
        }
        lifecycle {
          ignore_changes  = [ ssh_keys ]
          prevent_destroy = true
        }
      }
    '';

    "velocity.toml".text = ''
      config-version = "2.6"
      bind = "0.0.0.0:25577"
      motd = "<white>Velocity on kiwi is</white> <b><green>UP</green></b>"
      show-max-players = 44
      online-mode = true
      force-key-authentication = true
      prevent-client-proxy-connections = false
      player-info-forwarding-mode = "modern"
      forwarding-secret-file = "velocity.secret"
      announce-forge = false
      kick-existing-players = true
      ping-passthrough = "all"
      enable-player-address-logging = true

      [servers]
      ${auternasServerName} = "${auternasInternalIP}:25565"
      try = [ "${auternasServerName}" ]

      [forced-hosts]
      "${velocitySubdomain}.${hidden.ldryt.host}" = [ "${auternasServerName}" ]

      [advanced]
      compression-threshold = 256
      compression-level = 8
      login-ratelimit = 2000
      connection-timeout = 1500
      read-timeout = 10000
      haproxy-protocol = false
      tcp-fast-open = true
      bungee-plugin-message-channel = true
      show-ping-requests = true
      failover-on-unexpected-server-disconnect = true
      announce-proxy-commands = true
      log-command-executions = true
      log-player-connections = true
    '';
  };
}
