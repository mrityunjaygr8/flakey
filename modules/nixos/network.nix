{...}: {
  networking.networkmanager.enable = true;
  # Open ports in the firewall.
  # port 9090 is for calibre content server
  networking.firewall.allowedTCPPorts = [8000 3000 9090];
  networking.firewall.allowedUDPPorts = [9090];
}
