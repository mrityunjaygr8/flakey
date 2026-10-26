{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  agentDir = "${home}/.pi/agent";

  pi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  # pi reads provider credentials from the process environment (OPENCODE_API_KEY
  # for OpenCode Go). Source the sops-managed dotenv before handing over to pi.
  pi-wrapped = pkgs.symlinkJoin {
    name = "pi-wrapped";
    paths = [pi];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run 'if [ -f "${agentDir}/.env" ]; then set -a; . "${agentDir}/.env"; set +a; fi'
    '';
  };

  # pi rewrites settings.json itself (lastChangelogVersion, /settings), so it is
  # merged in place rather than linked read-only from the nix store.
  piSettingsMerge = pkgs.writeShellScript "pi-settings-merge" ''
    set -eu
    dir="$HOME/.pi/agent"
    file="$dir/settings.json"
    mkdir -p "$dir"
    tmp="$(mktemp "$dir/.settings.XXXXXX")"

    if [ -s "$file" ]; then
      ${pkgs.jq}/bin/jq \
        --arg provider 'opencode-go' \
        '.defaultProvider = $provider
         | .enabledModels = ["opencode-go/*"]
         | del(.defaultModel, .defaultThinkingLevel)' "$file" > "$tmp"
    else
      ${pkgs.jq}/bin/jq -n \
        --arg provider 'opencode-go' \
        '{defaultProvider: $provider, enabledModels: ["opencode-go/*"]}' > "$tmp"
    fi

    chmod 0600 "$tmp"
    mv "$tmp" "$file"
  '';

  piMcp = pkgs.writeText "pi-mcp.json" (
    builtins.replaceStrings
    ["@chromium@"]
    ["${pkgs.chromium}/bin/chromium"]
    (builtins.readFile ../../config/pi/mcp.json)
  );
in {
  home.packages = [pi-wrapped];

  # Same encrypted dotenv as omp/opencode/dsh, sourced by the pi wrapper.
  sops.secrets."harness-api-keys-pi" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "${agentDir}/.env";
  };

  home.activation.piConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p ${agentDir}

    # Re-assert the declarative model route without dropping pi-managed keys.
    run ${piSettingsMerge}

    # Seed MCP servers once; pi adds/removes entries in place afterwards.
    if [ ! -e ${agentDir}/mcp.json ]; then
      run ${pkgs.coreutils}/bin/install -m 0600 ${piMcp} ${agentDir}/mcp.json
    fi
  '';
}
