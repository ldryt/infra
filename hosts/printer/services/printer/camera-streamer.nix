{ pkgs, ... }:
let
  camera-streamer = pkgs.stdenv.mkDerivation {
    pname = "camera-streamer";
    version = "0.4.0";

    src = pkgs.fetchFromGitHub {
      owner = "ayufan";
      repo = "camera-streamer";
      tag = "v0.4.0";
      fetchSubmodules = true;
      hash = "sha256-XcMWZGHOA7oEOY6PVDPe1s+yO88z9778adx1rtIqbAQ=";
    };

    dontUseCmakeConfigure = true;
    NIX_CFLAGS_COMPILE = "-Wno-error";
    postPatch = ''
      substituteInPlace Makefile --replace-fail "git submodule update --init --recursive" "true"
    '';

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      xxd
    ];

    buildInputs = with pkgs; [
      ffmpeg
      libcamera
      live555
      v4l-utils
      openssl
    ];

    buildPhase = ''
      runHook preBuild
      make -j$NIX_BUILD_CORES
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m 755 camera-streamer $out/bin/
      runHook postInstall
    '';
  };
in
{
  services.mainsail.nginx.locations."/webcam/".proxyPass = "http://127.0.0.1:9999/";
  networking.firewall.interfaces."printertunnel".allowedTCPPorts = [ 9999 ];
  networking.firewall.interfaces."printertunnel".allowedUDPPorts = [ 9999 ];

  services.udev.extraRules = ''
    SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
  '';
  systemd.services.camera-streamer = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      SupplementaryGroups = [
        "video"
        "render"
      ];
      DevicePolicy = "closed";
      DeviceAllow = [
        "char-video4linux rw"
        "char-media rw"
        "char-dma_heap rw"
        "char-drm rw"
      ];
      ExecStart = "${camera-streamer}/bin/camera-streamer --camera-type=libcamera --camera-width=1024 --camera-height=768 --camera-hflip=1 --http-listen=0.0.0.0 --http-port=9999";
      Restart = "always";
      RestartSec = 10;
    };
  };
  environment.systemPackages = [
    pkgs.libcamera
    camera-streamer
  ];
}
