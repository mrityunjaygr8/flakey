{
  inputs,
  pkgs,
  config,
  ...
}: let
  cfg = config.home.homeDirectory;
in {
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
  ];

  sops.secrets."harness-api-keys" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "${cfg}/.omp/agent/.env";
  };

  home.file.".omp/agent/config.yml".source = ../../config/omp/config.yml;

  home.file.".omp/agent/ssh.json".source = ../../config/omp/ssh.json;
  home.file.".omp/agent/mcp.json".text =
    builtins.replaceStrings
    ["@chromium@"]
    ["${pkgs.chromium}/bin/chromium"]
    (builtins.readFile ../../config/omp/mcp.json);
}
