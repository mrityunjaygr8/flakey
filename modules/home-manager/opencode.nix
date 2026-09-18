{
  pkgs,
  inputs,
  config,
  ...
}: {
  programs.opencode = {
    enable = true;
    # package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    #   inherit (pkgs) bun;
    # };
    enableMcpIntegration = true;
    settings = {
      # OpenCode auto-discovers a vLLM server at 127.0.0.1:8000 (vLLM's default
      # port) every 30s via /health + /v1/models. Point that discovery at an
      # unused port so it stops probing the local Django dev server on 8000.
      provider.vllm.options.baseURL = "http://127.0.0.1:18099/v1";
      disabled_providers = ["vllm"];
    };
    package = pkgs.symlinkJoin {
      name = "op";
      paths = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode2 \
          --run 'if [ -f "$HOME/.config/opencode/.env" ]; then set -a; . "$HOME/.config/opencode/.env"; set +a; fi'
        ln -s $out/bin/opencode2 $out/bin/op
      '';
    };
  };
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      chrome-devtools = {
        command = "npx";
        args = ["-y" "chrome-devtools-mcp@latest" "--executablePath=${pkgs.chromium}/bin/chromium"];
      };
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer {env:GITHUB_TOKEN}";
        };
      };
    };
  };

  sops.secrets."harness-api-keys-opencode" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "${config.home.homeDirectory}/.config/opencode/.env";
  };
}
