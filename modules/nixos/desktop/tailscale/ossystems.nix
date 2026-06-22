{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.desktop.tailscale.ossystems;

  ts = config.services.tailscale.package;

  stateDir = "/var/lib/tailscale-ossystems";
  socket = "/run/tailscale-ossystems/tailscaled.sock";
  iface = "headscale0";

  # `tailscale` CLI pinned to this instance's socket
  tsctl = "${ts}/bin/tailscale --socket=${socket}";
in
{
  options.nixos.desktop.tailscale.ossystems = {
    enable = lib.mkEnableOption "second tailscaled instance for the ossystems Headscale";

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://vpn.infra.ossystems.io";
      description = "Headscale control server URL.";
    };

    authKeyFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets.ossystems-headscale-key.path;
      description = "File holding the Headscale pre-auth key.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The primary tailscaled (services.tailscale) owns tailscale0, the firewall
    # rules and the default socket. This second daemon gets its own everything
    # and runs with --netfilter-mode=off so it never flushes the primary's rules.
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "nixos.desktop.tailscale.ossystems requires the primary services.tailscale to be enabled (it provides the package).";
      }
    ];

    environment.systemPackages = [ ts ];

    systemd.tmpfiles.rules = [
      "d /run/tailscale-ossystems 0755 root root -"
      "d ${stateDir} 0700 root root -"
    ];

    # netfilter management is off on this instance, so the primary's ts-input
    # chain won't accept traffic arriving on headscale0 — trust it explicitly.
    networking.firewall.trustedInterfaces = [ iface ];

    systemd.services.tailscaled-ossystems = {
      description = "Tailscale daemon (ossystems Headscale)";
      after = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.iproute2
        pkgs.iptables
        pkgs.kmod
      ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${ts}/bin/tailscaled"
          "--state=${stateDir}/tailscaled.state"
          "--statedir=${stateDir}"
          "--socket=${socket}"
          "--tun=${iface}"
          "--port=0"
        ];
        Restart = "on-failure";
        RuntimeDirectory = "tailscale-ossystems";
        StateDirectory = "tailscale-ossystems";
      };
    };

    systemd.services.tailscaled-ossystems-autoconnect = {
      description = "Authenticate the ossystems Headscale tailscaled instance";
      after = [ "tailscaled-ossystems.service" ];
      wants = [ "tailscaled-ossystems.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        ts
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu

        # Wait for the daemon socket to come up.
        for _ in $(seq 1 30); do
          if ${tsctl} status --json --peers=false >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        state=$(${tsctl} status --json --peers=false | jq -r '.BackendState')
        if [ "$state" = "Running" ]; then
          echo "ossystems Headscale instance already running"
          exit 0
        fi

        ${tsctl} up \
          --login-server=${cfg.loginServer} \
          --auth-key="$(cat ${cfg.authKeyFile})" \
          --accept-routes \
          --accept-dns=false \
          --netfilter-mode=off
      '';
    };
  };
}
