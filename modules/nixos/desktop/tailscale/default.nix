{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.desktop.tailscale;
  updateScript = pkgs.writeShellApplication {
    name = "ts-update-script";
    runtimeInputs = with pkgs; [
      sops
      yq-go
      jq
      openssh
      curl
      git
    ];
    text = ''
      set -euo pipefail

      GITEA_HOST="http://192.168.68.111:3000"
      REPOSITORY="znaniye/nix-configs"
      GITEA_TOKEN=$(cat ${config.sops.secrets.gitea-pat-token.path})
      AUTH_HEADER="Authorization: token $GITEA_TOKEN"

      gitAuth() {
        git -c "http.extraHeader=$AUTH_HEADER" "$@"
      }

      if [ ! -d nix-configs ]; then
        gitAuth clone "$GITEA_HOST/$REPOSITORY.git"
      fi

      cd nix-configs
      git remote set-url origin "$GITEA_HOST/$REPOSITORY.git"
      gitAuth fetch origin master
      git checkout master
      gitAuth pull --rebase origin master
      git branch -D ts-update-pr 2>/dev/null || true
      git switch -C ts-update-pr
      git config user.name "tailscale-bot"
      git config user.email "tailscale-bot@localhost"

      file="secrets/var.yaml"

      createAuthKey () {
        local client_id client_secret tskey_api

        client_id=$(cat ${config.sops.secrets.ts-client-id.path})
        client_secret=$(cat ${config.sops.secrets.ts-client-secret.path})

        tskey_api=$(curl --silent --show-error --fail -d "client_id=$client_id" -d "client_secret=$client_secret" \
          "https://api.tailscale.com/api/v2/oauth/token" | jq -r .access_token)

        curl --silent --show-error --fail -X POST "https://api.tailscale.com/api/v2/tailnet/TMU2RwhAUm11CNTRL/keys" \
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
            "expirySeconds": 2592000
          }'
      }

      auth_response=$(createAuthKey)

      expires_at=$(echo "$auth_response" | jq -er .expires)
      expire_oncalendar=$(date -d "''${expires_at} -1 day" "+%Y-%m-%d %H:%M:%S UTC")
      cat > modules/nixos/desktop/tailscale/update.json <<EOF
      {"expires": "$expire_oncalendar"}
      EOF

      new_key=$(echo "$auth_response" | jq -er .key)
      export new_key
      sops -d -i "$file"
      yq -i '.tailscale-key = env(new_key)' $file
      sops -e -i "$file"

      git add modules/nixos/desktop/tailscale/update.json "$file"

      if git diff --cached --quiet; then
        echo "No tailscale key update to commit"
        exit 0
      fi

      git commit -m "chore(tailscale): rotate auth key"
      gitAuth push --force-with-lease origin ts-update-pr

      existing_pr=$(curl --silent --show-error --fail -H "$AUTH_HEADER" \
        "$GITEA_HOST/api/v1/repos/$REPOSITORY/pulls?state=open" \
        | jq -r 'map(select(.head.ref == "ts-update-pr" and .base.ref == "master")) | .[0].number // ""')

      if [ -n "$existing_pr" ]; then
        echo "Pull request #$existing_pr already open"
        exit 0
      fi

      pr_payload=$(jq -n \
        --arg title "chore(tailscale): rotate auth key" \
        --arg head "ts-update-pr" \
        --arg base "master" \
        --arg body "Automated tailscale auth key rotation." \
        '{ title: $title, head: $head, base: $base, body: $body }')

      curl --silent --show-error --fail -X POST \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d "$pr_payload" \
        "$GITEA_HOST/api/v1/repos/$REPOSITORY/pulls"
    '';
  };

in
{
  options.nixos.desktop.tailscale.enable = lib.mkEnableOption "tailscale config (client side)" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enable {

      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-key.path;
        #useRoutingFeatures = if config.nixos.server.tailscale.enable then "both" else "client";
      };

      # Disable wait online as it's causing trouble at rebuild
      # See: https://github.com/NixOS/nixpkgs/issues/180175
      systemd.services.NetworkManager-wait-online.enable = false;
    })

    (lib.mkIf (cfg.enable && config.networking.hostName == "tortinha") {
      systemd.tmpfiles.rules = [
        "d /var/lib/ts-auth-auto-update 0700 root root -"
      ];

      systemd.timers.ts-auth-auto-update =
        let
          date = builtins.fromJSON (builtins.readFile ./update.json);
        in
        {
          description = "Run script 1 day before expiration.";
          wantedBy = [ "timers.target" ];
          timerConfig.OnCalendar = date.expires;
          timerConfig.Persistent = true;
        };

      systemd.services.ts-auth-auto-update = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "30min";
          WorkingDirectory = "/var/lib/ts-auth-auto-update";
          Environment = [
            "HOME=/home/${config.meta.username}"
          ];
          ExecStart = "${updateScript}/bin/ts-update-script";
        };
      };
    })
  ];
}
