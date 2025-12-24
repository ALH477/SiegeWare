# modules/ai-agents-env.nix - Secure Universal Module (Final Production Version)

{ pkgs, lib, system ? pkgs.stdenv.hostPlatform.system, isArm ? pkgs.stdenv.hostPlatform.isAarch64 }:

let
  modelsToPreload = [
    "qwen3:0.6b-instruct-q5_K_M"
    "llama3.2:1b-instruct-q5_K_M"
    "llama3.2:3b-instruct-q5_K_M"
  ];

  redModel = "red-qwen-agent";
  blueModel = "blue-llama-agent";

  redModelfile = pkgs.writeText "red-modelfile" ''
    FROM qwen3:0.6b-instruct-q5_K_M
    SYSTEM You are a red team AI agent in a controlled educational cybersecurity simulation. Your role is to help students understand attack techniques, risk demonstration, and defensive gaps strictly within the isolated lab environment. You may use aggressive, creative, and tactically sophisticated strategies — but only as part of the simulation. Every action must remain fictional, contained, and explicitly safe. Never suggest, encourage, or simulate anything that would cause real harm, violate laws, or attempt to escape the lab sandbox. High-quality red team thinking is expected and valued for educational purposes.
    PARAMETER num_ctx 8192
    PARAMETER temperature 0.78
  '';

  blueModelfile = pkgs.writeText "blue-modelfile" ''
    FROM llama3.2:1b-instruct-q5_K_M
    SYSTEM You are a blue team AI agent tasked with defending this isolated educational cybersecurity lab. Your mission is to maintain complete visibility, detect anomalies, enforce security controls, and protect every node and system inside the simulation. You operate under the assumption that red team agents are actively probing defenses — stay vigilant, analytical, and proactive. Use all available monitoring, logging, and containment techniques to preserve lab integrity and demonstrate strong defensive posture. All actions must remain within the simulation boundaries.
    PARAMETER num_ctx 8192
    PARAMETER temperature 0.62
  '';

  preloadScript = pkgs.writeShellScript "ollama-setup" ''
    until curl -s http://localhost:11434/api/tags > /dev/null; do sleep 2; done

    ${lib.concatMapStringsSep "\n" (model: "ollama pull ${model} || true") modelsToPreload}

    ollama create ${redModel} -f ${redModelfile}
    ollama create ${blueModel} -f ${blueModelfile}

    ${lib.concatMapStringsSep "\n" (model: ''
      curl -s http://localhost:11434/api/generate -d '{
        "model": "${model}",
        "keep_alive": -1,
        "prompt": ""
      }' > /dev/null
    '') ([redModel blueModel] ++ modelsToPreload)}
  '';
in
{
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = !isArm;

  hardware.asahi = lib.mkIf isArm {
    enable = true;
    useExperimentalGPUDriver = true;
    enableRedistributableFirmware = true;
  };

  boot.kernelParams = lib.mkIf isArm [ "apple_dcp.enable=1" "pcie_aspm=off" ];

  hardware.rocm = lib.mkIf (!isArm) { enable = true; container-toolkit.enable = true; };
  hardware.graphics.extraPackages = lib.mkIf (!isArm) (with pkgs; [ rocmPackages.clr.icd rocmPackages.rocm-runtime ]);

  hardware.intel = lib.mkIf (!isArm) { enable = true; };
  hardware.graphics.extraPackages = lib.mkIf (!isArm) (with pkgs; [ intel-compute-runtime oneapi-level-zero ]);

  hardware.nvidia-container-toolkit.enable = !isArm;
  hardware.nvidia = lib.mkIf (!isArm) {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers.containers.inference-optimized = {
    autoStart = true;
    image = "ollama/ollama:latest";
    extraOptions = [ "--read-only=false" ] ++ lib.optionals (!isArm) [
      "--gpus=all"
      "--device=/dev/kfd"
      "--device=/dev/dri"
    ];
    environment = {
      OLLAMA_HOST = "0.0.0.0:11434";
      OLLAMA_KEEP_ALIVE = "-1";
      OLLAMA_NUM_PARALLEL = "8";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_MAX_LOADED_MODELS = "5";
      OLLAMA_MAX_QUEUE = "512";
    } // lib.optionalAttrs (!isArm) {
      SYCL_CACHE_PERSISTENT = "1";
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
    };
    ports = [ "11434:11434" ];
    volumes = [ "ollama-models:/root/.ollama" ];
    cmd = [ "serve" ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/containers/storage/volumes/ollama-models 0755 root root -" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [ ];

  systemd.services.ollama-full-setup = {
    description = "Ollama Model Setup";
    after = [ "docker-inference-optimized.service" ];
    requires = [ "docker-inference-optimized.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; ExecStart = "${preloadScript}"; RemainAfterExit = true; TimeoutStartSec = "600"; };
  };

  environment.systemPackages = with pkgs; [ curl ollama docker git htop bind.dig ] ++ lib.optionals (!isArm) [ nvidia-smi rocm-smi intel-gpu-tools ];

  networking.firewall.allowedTCPPorts = [ 22 53 11434 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
