{
  inputs,
  pkgs,
  config,
  ...
}: let
  cfg = config.home.homeDirectory;
  lspPackages = import ../../home-manager/common/lsp-packages.nix pkgs;
  omp-wrapped = pkgs.symlinkJoin {
    name = "omp-wrapped";
    paths = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/omp \
        --prefix PATH : ${pkgs.lib.makeBinPath lspPackages}
    '';
  };
in {
  home.packages = [omp-wrapped inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.junie];

  sops.secrets."harness-api-keys" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "${cfg}/.omp/agent/.env";
  };

  home.file = {
    ".omp/agent/config.yml".source = ../../config/omp/config.yml;
    ".omp/agent/ssh.json".source = ../../config/omp/ssh.json;
    # ".omp/agent/APPEND_SYSTEM.md".source = ../../config/omp/APPEND_SYSTEM.md;
    ".omp/agent/mcp.json".text =
      builtins.replaceStrings
      ["@chromium@"]
      ["${pkgs.chromium}/bin/chromium"]
      (builtins.readFile ../../config/omp/mcp.json);

    ".omp/agent/rules" = {
      source = ../../config/omp/rules;
      recursive = true;
    };
  };
}
