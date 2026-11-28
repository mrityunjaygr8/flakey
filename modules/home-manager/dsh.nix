{
  inputs,
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;

  # dsh resolves provider credentials from the process environment first, then
  # its .credentials.yaml/.env layers. Ambient OPENCODE_API_KEY values (for
  # example from a running OpenCode session) would otherwise win over the
  # sops-managed key, so source the dotenv before handing over to dsh.
  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "dsh-wrapped";
      paths = [dsh];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/dsh \
          --run 'if [ -f "$HOME/.dsh/.env" ]; then set -a; . "$HOME/.dsh/.env"; set +a; fi'
      '';
    })
  ];

  # Same encrypted dotenv as omp/opencode/pi, exposed as dsh's user-level env
  # layer (~/.dsh/.env). DEEPSEEK_API_KEY and provider keys are allowed there;
  # DSH_* bootstrap variables are not.
  sops.secrets."harness-api-keys-dsh" = {
    format = "dotenv";
    sopsFile = ../../secrets/home/mgr8/harness-api-keys.env;
    path = "${home}/.dsh/.env";
  };

  # Deployer-owned home patch (read-only is fine: the dsh UI writes per-profile
  # patches, never the home-level one).
  home.file.".dsh/cordis.patch.yml".source = ../../config/dsh/cordis.patch.yml;
}
