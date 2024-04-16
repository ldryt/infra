{ ... }:
{
  home.shellAliases = {
    "windows" = "nix shell nixpkgs#freerdp -c wlfreerdp /u:docker /p: /v:127.0.0.1:3389 -encryption +clipboard /rfx /gfx:rfx /f /floatbar:sticky:off +gestures +fonts /bpp:32 /audio-mode:0 +aero +window-drag /size:120 &";
  };
}
