{ pkgs, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "useless@useless.com";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    package = (
      pkgs.nginxMainline.override {
        modules = [ pkgs.nginxModules.moreheaders ];
      }
    );

    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      more_set_headers "Strict-Transport-Security: $hsts_header";

      # Minimize information leaked to other domains
      more_set_headers "Referrer-Policy: origin-when-cross-origin";

      # Disable embedding as a frame
      more_set_headers "X-Frame-Options: SAMEORIGIN";

      # Prevent injection of code in other mime types (XSS Attacks)
      more_set_headers "X-Content-Type-Options: nosniff";

      more_set_headers "X-Robots-Tag: noindex, nofollow, nosnippet, noarchive";
    '';
  };
}
