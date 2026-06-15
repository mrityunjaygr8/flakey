{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
  ];
  sops.secrets."harness-api-keys" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "%r/harness-api-keys.env";
  };
}
