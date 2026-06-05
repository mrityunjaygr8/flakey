{pkgs, ...}: {
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    9000 # Traefik ingress HTTP
    9443 # Traefik ingress HTTPS
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  services.k3s = {
    enable = true;
    role = "server";
    configPath = "/home/arr/.kube/config";
    extraFlags = toString [
      # "--debug" # Optionally add additional args to k3s
      "--write-kubeconfig-mode 640"
      "--write-kubeconfig-group k3sconfig"
    ];
  };
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  users.groups.k3sconfig = {};
  users.users.arr.extraGroups = ["k3sconfig"];

  # Override Traefik entrypoints to use ports 9000/9443 instead of 8000/8443
  systemd.tmpfiles.rules = let
    traefikConfig = pkgs.writeText "traefik-config.yaml" ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChartConfig
      metadata:
        name: traefik
        namespace: kube-system
      spec:
        valuesContent: |
          ports:
            web:
              port: 9000
              exposedPort: 9000
            websecure:
              port: 9443
              exposedPort: 9443
    '';
  in [
    "d /var/lib/rancher/k3s/server/manifests 0755 root root -"
    "C /var/lib/rancher/k3s/server/manifests/traefik-config.yaml 0644 root root - ${traefikConfig}"
  ];
}
