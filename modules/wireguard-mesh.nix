{ config, lib, ... }:
let
  cfg = config.ldryt-infra.wireguard-meshes;
  host = config.networking.hostName;

  active = lib.filterAttrs (_: mesh: mesh.peers ? ${host}) cfg;

  peersFor =
    mesh:
    let
      others = lib.filterAttrs (n: _: n != host) mesh.peers;
    in
    if mesh.hub == null then
      others # full mesh
    else if host == mesh.hub then
      others # hub -> every spoke
    else
      lib.filterAttrs (n: _: n == mesh.hub) mesh.peers; # spoke -> hub only

  mkPeer = mesh: peerName: peer: {
    inherit (peer) publicKey;
    allowedIPs = [ "${peer.ip}/32" ];
    endpoint =
      if peer.endpoint != null then
        peer.endpoint
      else
        "${peerName}.${config.ldryt-infra.dns.zone}:${toString mesh.port}";
    persistentKeepalive = 25;
  };
in
{
  options.ldryt-infra.wireguard-meshes = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            interface = lib.mkOption {
              type = lib.types.str;
              default = "wg-${name}";
            };
            port = lib.mkOption { type = lib.types.port; };
            subnet = lib.mkOption { type = lib.types.str; };
            hub = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            privateKeyFile = lib.mkOption { type = lib.types.path; };
            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            peers = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    ip = lib.mkOption { type = lib.types.str; };
                    publicKey = lib.mkOption { type = lib.types.str; };
                    endpoint = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                    };
                  };
                }
              );
            };
          };
        }
      )
    );
  };

  config = {
    networking.wireguard.interfaces = lib.mapAttrs' (
      _: mesh:
      lib.nameValuePair mesh.interface {
        ips = [ "${mesh.peers.${host}.ip}/${lib.last (lib.splitString "/" mesh.subnet)}" ];
        listenPort = mesh.port;
        inherit (mesh) privateKeyFile;
        peers = lib.mapAttrsToList (mkPeer mesh) (peersFor mesh);
      }
    ) active;

    networking.firewall.allowedUDPPorts = lib.concatMap (
      mesh: lib.optionals mesh.openFirewall [ mesh.port ]
    ) (lib.attrValues active);
  };
}
