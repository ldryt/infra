{ config, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "Paperless on ${config.ldryt-infra.dns.records.immich}";
      client_id = "M_3u3h400bGpZITw.v4uzY3AcauXnQ2oN-QOBArXDVnN8H6CCk~kF5umSLIlRkG5oV5Nxemv";
      client_secret = "$pbkdf2-sha512$310000$xCOoEJ0nghjn3OJHEO5I6Q$9uSJ1oypI6pdTe2VAryBtHYKAzS3nW69S1sH1..p.U4grYNEoAizZc6qLYEw2AnoDuk6wTyIzENcQpIuBGa4Bw";
      public = false;
      consent_mode = "pre-configured";
      pre_configured_consent_duration = "14 days";
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [
        "https://${config.ldryt-infra.dns.records.paperless}/accounts/oidc/authelia/login/callback/"
      ];
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      response_types = [
        "code"
      ];
      grant_types = [
        "authorization_code"
      ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    }
  ];
}
