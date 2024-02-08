{ ... }:
let hidden = import ../secrets/obfuscated.nix;
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = hidden.ldryt.email;
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    sslProtocols = "TLSv1.3";
    appendHttpConfig = ''
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';
  };
}
