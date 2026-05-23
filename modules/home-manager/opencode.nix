{
  pkgs,
  inputs,
  ...
}: {
  programs.opencode = {
    enable = true;
    # package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    #   inherit (pkgs) bun;
    # };
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    enableMcpIntegration = true;
    skills = {
      graphify = ../../config/opencode/skills/graphify;
    };
    agents = {
      graphify = ../../config/opencode/agents/graphify.md;
    };
    settings = {
      plugin = ["./opencode/plugins/graphify"];
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

  xdg.configFile = {
    "opencode/plugins" = {
      source = ../../config/opencode/plugins;
      recursive = true;
    };
  };
}
