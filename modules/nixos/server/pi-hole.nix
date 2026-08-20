{
  config,
  lib,
  ...
}:

{

  config = lib.mkIf config.nixos.server.pi-hole.enable {
    networking.firewall.allowedTCPPorts = [
      53
    ];
    networking.firewall.allowedUDPPorts = [
      53
    ];
    services = {
      pihole-ftl = {
        enable = true;
        lists = [
          {
            # Alternatively, use the file from nixpkgs. Note its contents won't be
            # automatically updated by Pi-hole, as it would with an online URL.
            # url = "file://${pkgs.stevenblack-blocklist}/hosts";
            description = "Steven Black's unified adlist";
            url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          }
        ];
        openFirewallDHCP = true;
        openFirewallDNS = true;
        queryLogDeleter = {
          age = 120;
          enable = true;
        };
        settings = {
          dhcp = {
            active = false;
          };
          dns = {
            domainNeeded = false;
            expandHosts = true;
            interface = "all";
            listeningMode = "all";
            upstreams = [
              "1.1.1.1"
              "2606:4700:4700::1111"
              "9.9.9.11"
              "2620:fe::11"
            ];
          };
        };
      };
      pihole-web = {
        enable = true;
        ports = [
          8053
        ];
      };
    };
  };
  options.nixos.server.pi-hole.enable = lib.mkEnableOption "pihole config" // {
    default = config.nixos.server.enable;
  };
}
