{ pkgs, ... }:
{
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [
        "127.0.0.1:53"
        "[::1]:53"
      ];
      http3 = true;
      server_names = [ "NextDNS-c1dca3" ];
      static = {
        "NextDNS-c1dca3" = {
          stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2MxZGNhMw";
        };
      };
      sources = { };
    };
  };

  networking = {
    nameservers = [ ];
    networkmanager = {
      settings.connectivity = {
        enable = true;
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        response = "NetworkManager is online";
      };
      dispatcherScripts = [
        {
          source = pkgs.writeShellScript "networkmanager-dnscrypt" ''
            set -eu

            iface="$1"
            state="$2"
            case "$state" in
              up|connectivity-change) ;;
              *) exit 0 ;;
            esac

            nmcli="${pkgs.networkmanager}/bin/nmcli"
            connectivity="$($nmcli -t -f CONNECTIVITY general)"
            if [ "$connectivity" = full ]; then
              "$nmcli" device modify "$iface" \
                ipv4.ignore-auto-dns yes ipv4.dns 127.0.0.1 \
                ipv6.ignore-auto-dns yes ipv6.dns ::1
            else
              "$nmcli" device modify "$iface" \
                ipv4.ignore-auto-dns no ipv4.dns "" \
                ipv6.ignore-auto-dns no ipv6.dns ""
            fi
          '';
        }
      ];
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
