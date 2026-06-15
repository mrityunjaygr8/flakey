{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    # Use your SSH key (must be passwordless, or use a separate age key)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
