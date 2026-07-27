{ inputs, config, lib, pkgs, ... }:
let
  modelDir = "/models";
  modelFile = "${modelDir}/unsloth/GLM-5.2-GGUF/UD-IQ2_M/GLM-5.2-UD-IQ2_M-00001-of-00006.gguf";
in
{
  disabledModules = [ "services/misc/llama-cpp.nix" ];
  imports = [ "${inputs.nixpkgs-master}/nixos/modules/services/misc/llama-cpp.nix" ];

  nixpkgs.config = {
    cudaCapabilities = [ "9.0" ];
    cudaForwardCompat = false;
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = false;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  boot.kernel.sysctl."vm.swappiness" = 0;

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    settings = {
      model = modelFile;
      alias = "glm-5.2";
      host = "127.0.0.1";
      port = 8080;
      n-gpu-layers = 999;
      cpu-moe = true;
      ctx-size = 131072;
      parallel = 1;
      flash-attn = "on";
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
      batch-size = 4096;
      ubatch-size = 2048;
      threads = 30;
      cache-reuse = 256;
      cache-ram = 32768;
      cache-idle-slots = true;
      jinja = true;
      reasoning-format = "auto";
      temp = 1.0;
      top-p = 0.95;
      min-p = 0.01;
    };
  };

  systemd.services.fetch-model = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig = {
      ConditionPathExists = "!${modelFile}";
      RequiresMountsFor = modelDir;
    };
    path = [ pkgs.python314Packages.huggingface-hub ];
    environment = {
      HF_HOME = "${modelDir}/.hf";
      HF_XET_CACHE = "${modelDir}/.hf/xet";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "0";
    };
    script = ''
      hf download unsloth/GLM-5.2-GGUF --local-dir ${modelDir}/unsloth/GLM-5.2-GGUF --include "*UD-IQ2_M*"
    '';
  };

  systemd.services.llama-cpp = {
    after = [ "fetch-model.service" ];
    requires = [ "fetch-model.service" ];
    serviceConfig.RestartSec = lib.mkForce 10;
  };
}
