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
    package = (inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.override
      {
        inherit (pkgs) bun;
      }).overrideAttrs (old: {
      preBuild =
        (old.preBuild or "")
        + ''
          substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
            --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
            --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
            --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
        '';
    });
    enableMcpIntegration = true;
    settings = {};
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
        args = ["-y" "chrome-devtools-mcp@latest" "--executablePath=$HOME/.nix-profile/bin/chromium"];
      };
    };
  };
}
