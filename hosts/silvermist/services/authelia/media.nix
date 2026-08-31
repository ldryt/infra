{ config, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc = {
    authorization_policies.seerr = {
      default_policy = "deny";
      rules = [
        {
          subject = [
            "group:admin"
            "group:media"
          ];
          policy = "one_factor";
        }
      ];
    };

    clients = [
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
      {
        client_name = "Seerr";
        client_id = "seerr";
        client_secret = "$pbkdf2-sha512$310000$Ws6RubtEcH1EIGS76JKB6Q$OAFZgyiMaK9ILT7qrCtXPVHyiCfuEfjEXKDdNi8l12TMhE0EsOCq9RqWBO9oSRreA5qFc34xGimNaryYGDKylA";
        public = false;
        authorization_policy = "seerr";
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [
          "https://${config.ldryt-infra.dns.records.seerr}/login"
          "https://${config.ldryt-infra.dns.records.seerr}/profile/settings/linked-accounts"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "client_secret_post";
      }
    ];
  };
}
