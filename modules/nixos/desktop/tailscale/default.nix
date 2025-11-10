{
  config,
  lib,
  pkgs,
  ...
}:
let
  updateScript = pkgs.writeShellApplication {
    name = "ts-update-script";
    runtimeInputs = with pkgs; [
      sops
      yq-go
      jq
      openssh
      curl
      git
      gh
    ];
    text = ''
      set -euo pipefail
      GITHUB_TOKEN=$(cat ${config.sops.secrets.gh-token.path})
      export GITHUB_TOKEN

      if [ ! -d nix-configs ]; then
        git clone https://github.com/znaniye/nix-configs.git
      fi
      cd nix-configs
      git fetch origin master
      git switch master
      git branch -D ts-update-pr 2>/dev/null || true
      git switch -c ts-update-pr

      file="secrets/var.yaml"

      createAuthKey () {
        local client_id client_secret tskey_api

        client_id=$(cat ${config.sops.secrets.ts-client-id.path})
        client_secret=$(cat ${config.sops.secrets.ts-client-secret.path})

        tskey_api=$(curl -s -d "client_id=$client_id" -d "client_secret=$client_secret" \
          "https://api.tailscale.com/api/v2/oauth/token" | jq -r .access_token)

        curl -s -X POST "https://api.tailscale.com/api/v2/tailnet/TMU2RwhAUm11CNTRL/keys" \
          -H "Authorization: Bearer $tskey_api" \
          -H "Content-Type: application/json" \
          -d '{
            "capabilities": {
              "devices": {
                "create": {
                  "reusable": false,
                  "ephemeral": false,
                  "preauthorized": true,
                  "tags": ["tag:server"]
                }
              }
            },
            "expirySeconds": 7776000
          }'
      }

      auth_response=$(createAuthKey)

      expires_at=$(echo "$auth_response" | jq -r .expires)
      expire_oncalendar=$(date -d "''${expires_at} -1 day" "+%Y-%m-%d %H:%M:%S UTC")
      cat > modules/nixos/desktop/tailscale/update.json <<EOF
      {"expires": "$expire_oncalendar"}
      EOF

      new_key=$(echo "$auth_response" | jq -r .key)
      export new_key
      sops -d -i "$file"
      yq -i '.tailscale-key = env(new_key)' $file
      sops -e -i "$file"

      git add -u
      git commit -m "bump ts auth key"
      git push --force-with-lease origin ts-update-pr
      gh pr create --fill || echo "branch exists"
    '';
  };

in
{
  options.nixos.desktop.tailscale.enable = lib.mkEnableOption "tailscale config (client side)" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.tailscale.enable {

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale-key.path;
      #useRoutingFeatures = if config.nixos.server.tailscale.enable then "both" else "client";
    };

    # Disable wait online as it's causing trouble at rebuild
    # See: https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;

    systemd.tmpfiles.rules = [
      "d /var/lib/ts-auth-auto-update 0755 root root -"
    ];

    systemd.timers.ts-auth-auto-update =
      let
        date = builtins.fromJSON (builtins.readFile ./update.json);
      in
      {
        description = "Run script 1 day before expiration.";
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = date.expires;
      };

    systemd.services.ts-auth-auto-update = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/var/lib/ts-auth-auto-update";
        Environment = [
          "HOME=/home/${config.meta.username}"
        ];
        ExecStart = "${updateScript}/bin/ts-update-script";
      };
    };
  };
}
