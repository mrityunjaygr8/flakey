{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    amdgpu_top
  ];

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1031";
    };
    rocmOverrideGfx = "10.3.1";
  };

  services.open-webui.enable = true;
}
