{ config, ... }:
let
  oidcSigningAlg = "RS256";
  oidcClientID = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
in
{
  services.authelia.instances.main.settings = {
    definitions.user_attributes = {
      "immich_role" = {
        expression = ''"admin" in groups ? "admin" : "user"'';
      };
    };
    authentication_backend.file.extra_attributes = {
      "immich_quota" = {
        multi_valued = false;
        value_type = "integer";
      };
    };
    identity_providers.oidc = {
      claims_policies.immich_policy.custom_claims = {
        "immich_quota".attribute = "immich_quota";
        "immich_role".attribute = "immich_role";
      };
      scopes."immich_scope".claims = [
        "immich_quota"
        "immich_role"
      ];
      clients = [
        {
          client_name = "immich2";
          client_id = oidcClientID;
          client_secret = "$pbkdf2-sha512$310000$BnofSrb/7axDYm4xu.8Oiw$KdpSMxSSOf0JolMmcGJX.wyRFulmjz115rDTWefXkH4wNrnwezFJVx3tHzjr3.eVo7ywnmcrydLbZTMTSK/RLQ";
          public = false;
          consent_mode = "pre-configured";
          pre_configured_consent_duration = "1 month";
          redirect_uris = [
            "https://${config.ldryt-infra.dns.records.immich2}/auth/login"
            "https://${config.ldryt-infra.dns.records.immich2}/user-settings"
            "app.immich:///oauth-callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "immich_scope"
          ];
          claims_policy = "immich_policy";
          userinfo_signed_response_alg = oidcSigningAlg;
          id_token_signed_response_alg = oidcSigningAlg;
          token_endpoint_auth_method = "client_secret_post";
          require_pkce = false;
        }
      ];
    };
  };
}
