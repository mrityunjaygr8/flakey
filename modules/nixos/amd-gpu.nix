{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    amdgpu_top
  ];

  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };
}
