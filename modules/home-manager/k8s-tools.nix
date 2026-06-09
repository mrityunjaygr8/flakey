{pkgs, ...}: {
  home.packages = with pkgs; [
    k9s
    kubeseal
    kubernetes-helm
    fluxcd
  ];
}
