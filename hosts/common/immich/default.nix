{ pkgs-master, ... }:
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
    port = 3003; # https://github.com/immich-app/immich/blob/7acda0572dc3349977d1aa66e90a3ef1474583fa/machine-learning/immich_ml/config.py#L96
    clipModel = "ViT-SO400M-16-SigLIP2-384__webli"; # https://docs.immich.app/features/searching/#clip-models
    ocrModel = "PP-OCRv5_server"; # https://huggingface.co/collections/PaddlePaddle/pp-ocrv5;
    facialModel = "buffalo_l";
  };
  wg = {
    int = "wg-immich";
    subnet = "/24";
    port = 51820;
    silvermist = {
      ip = "10.114.44.1";
      pubKey = "CzUHVmitMA/I/j7p0E0pW2IYtVx7r+ofgUGMC5roEnk=";
    };
    luke = {
      ip = "10.114.44.2";
      pubKey = "+OpKi943ZB5i18dFxBmjV4Eu5t9fv6AcMJyYKq272kA=";
    };
  };
  immichPkg = pkgs-master.immich.override {
    immich-machine-learning = pkgs-master.immich-machine-learning.override {
      python3 = pkgs-master.python3.override {
        packageOverrides = final: prev: {
          rapidocr = prev.rapidocr.overridePythonAttrs (old: rec {
            version = "3.7.0";
            src = pkgs-master.fetchFromGitHub {
              owner = "RapidAI";
              repo = "RapidOCR";
              tag = "v${version}";
              hash = "sha256-wFAW0KRNC31cqJ8f1/dBZDLSkOBdB5AFpPzO85g3rHA=";
            };
          });
        };
      };
    };
  };
}
