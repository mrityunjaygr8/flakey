{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ollama-rocm
    amdgpu-top
  ];
}
