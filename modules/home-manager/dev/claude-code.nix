{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.dev;
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ jq ];

    nixpkgs = {
      config.allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "claude-code"
          "claude"
        ];
    };

    programs.claude-code = {
      enable = true;
      settings = {
        model = "opus";
        skipDangerousModePermissionPrompt = true;
        alwaysThinkingEnabled = true;
        permissions = {
          allow = [
            "Bash(cat:*)"
            "Bash(cd:*)"
            "Bash(echo:*)"
            "Bash(git add:*)"
            "Bash(git branch:*)"
            "Bash(git commit:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git remote -v:*)"
            "Bash(git rev-parse:*)"
            "Bash(git show:*)"
            "Bash(git stash list:*)"
            "Bash(git status:*)"
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(pwd:*)"
            "Bash(which:*)"
            "Bash(tree:*)"
            "Bash(mkdir:*)"
            "Bash(npm run:*)"
            "Bash(npm test:*)"
            "Bash(npm install:*)"
            "Bash(npm ci:*)"
            "Bash(npx:*)"
            "Bash(node:*)"
            "Bash(go build:*)"
            "Bash(go test:*)"
            "Bash(go vet:*)"
            "Bash(go fmt:*)"
            "Bash(go mod tidy:*)"
            "Bash(make:*)"
            "Bash(terraform fmt:*)"
            "Bash(terraform validate:*)"
            "Bash(terraform plan:*)"
            "Bash(tofu fmt:*)"
            "Bash(tofu validate:*)"
            "Bash(tofu plan:*)"
            "Bash(gh pr:*)"
            "Bash(gh issue:*)"
            "Bash(gh repo view:*)"
            "Bash(jq:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(sort:*)"
            "Bash(uniq:*)"
            "Bash(diff:*)"
            "Bash(nix build:*)"
            "Bash(nix flake check:*)"
            "Bash(nix flake show:*)"
            "Bash(nix flake metadata:*)"
            "Bash(nix fmt:*)"
            "Bash(nix eval:*)"
            "Bash(nix develop:*)"
            "Bash(nix log:*)"
            "Bash(nix path-info:*)"
            "Bash(nix search:*)"
            "Bash(nixfmt:*)"
            "Read"
            "Edit"
            "Write"
            "Glob"
            "Grep"
            "Agent"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:mynixos.com)"
            "WebSearch"
          ];
          deny = [
            "Bash(rm -rf:*)"
            "Bash(git push --force:*)"
            "Bash(git reset --hard:*)"
            "Bash(git clean -f:*)"
            "Bash(terraform apply:*)"
            "Bash(tofu apply:*)"
            "Bash(terraform destroy:*)"
            "Bash(tofu destroy:*)"
            "Bash(sbt publish:*)"
          ];
        };
        attribution = {
          commit = "";
          pr = "";
        };
        hooks = {
          Notification = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
                }
                {
                  type = "command";
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Session needs your attention' 2>/dev/null || true";
                }
              ];
            }
          ];
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
                }
                {
                  type = "command";
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Task finished' 2>/dev/null || true";
                }
              ];
            }
          ];
        };

        # Plugin marketplace configuration
        extraKnownMarketplaces = {
          ossystems = {
            source = {
              source = "github";
              repo = "OSSystems/claude-code-plugin";
            };
          };
        };

        enabledPlugins = {
          "ossystems-commit@ossystems" = true;
        };
      };
    };
  };
}
