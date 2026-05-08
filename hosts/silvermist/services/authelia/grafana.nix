{ config, ... }:
{
  # https://www.authelia.com/integration/openid-connect/grafana/
  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_name = "grafana";
      client_id = "2NADHAc~yxd~kNvfJg4PwJNXE1ErhAcQ2~9FPZEh2TgxLY_GIJdv1LluQGKv38iSy~JYNxo.";
      client_secret = "$pbkdf2-sha512$310000$JcOWa7BjnZ.spylrhrwBUA$1ztZ/nyYgD1Ke2VQ09WNAh5Cc0ORSYw7vm4Icg7xO5l3AcvpZ1tI9P3uyvGzYhxNVko0fmXtJxalCIvwF5eGcA";
      public = false;
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [ "https://${config.ldryt-infra.dns.records.grafana}/login/generic_oauth" ];
      scopes = [
        "openid"
        "profile"
        "groups"
        "email"
      ];
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    }
  ];
}
