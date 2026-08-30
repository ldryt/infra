{ config, ... }:
{
  services.authelia.instances.main.settings.access_control.rules = [
    {
      domain = config.ldryt-infra.dns.records.seerr;
      subject = [ "group:media" ];
      policy = "one_factor";
    }
  ];

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "Jellyfin";
      client_id = "jellyfin";
      client_secret = "$pbkdf2-sha512$310000$k.9SE5sJ8pEn3w9wCX0i/Q$xwtsEdj2LKjJNqoAs.plyBtqPDugYLWZVUZy/yAzcgBeE9O0aEFmd46Kg./KcbEcruZBW3hhLBGpHcZvXCHVTw";
      public = false;
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [
        "https://${config.ldryt-infra.dns.records.jellyfin}/sso/OID/redirect/authelia"
      ];
      scopes = [
        "openid"
        "profile"
        "groups"
      ];
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      token_endpoint_auth_method = "client_secret_post";
    }
  ];
}
