{
  dataDir = "/mnt/immich";
  gdriveArchiveMount = "/mnt/gdrive-photos-2004-2017";
  oidc = {
    signingAlg = "RS256";
    clientID = "YL~WkjeeJXxVWOs01mdJjXJarT6yssLlf4yZdAowKL61OWpP3G2WbR1D9y2RBAjh_xHSXRGo";
  };
  smtpSender = "pics@ldryt.dev";
  redis.port = 46379;
  ml = {
    port = 43003;
    model = "ViT-B-16-SigLIP__webli";
  };
}
