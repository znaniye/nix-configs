{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.editor.vscode;
  anthropicBaseUrl = "http://192.168.150.11:4444";

  claudeCodeExtensionBase = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "claude-code";
      publisher = "anthropic";
      version = "2.1.92";
      hash = "sha256-f+6xXZVb5sYrmrH7eoon6/QoQaTnBuTnb+YnvszqyKA=";
    };
  };

  claudeCodeExtension = claudeCodeExtensionBase.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      extensionClaude="$out/share/vscode/extensions/anthropic.claude-code/resources/native-binary/claude"
      if [ -f "$extensionClaude" ]; then
        printf '%s\n' \
          '#!${pkgs.bash}/bin/bash' \
          'exec ${pkgs.claude-code}/bin/claude "$@"' \
          > "$extensionClaude"
        chmod +x "$extensionClaude"
      fi
    '';
  });

  pencilExtensionBase = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "pencildev";
      publisher = "highagency";
      version = "0.6.38";
      hash = "sha256-SpmKjxBttOdMCrPCxvXp93ZnS+UAd0vRxAOx0BSKIuc=";
    };
  };

  pencilExtension = pencilExtensionBase.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      mcpBinary="$out/share/vscode/extensions/highagency.pencildev/out/mcp-server-linux-x64"
      if [ -f "$mcpBinary" ]; then
        mv "$mcpBinary" "$mcpBinary.real"
        cat > "$mcpBinary" <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.stdenv.cc.bintools.dynamicLinker} --library-path ${
        pkgs.lib.makeLibraryPath [ pkgs.glibc ]
      } "$mcpBinary.real" "\$@"
      EOF
        chmod +x "$mcpBinary"
      fi
    '';
  });

  vscodiumWithAnthropicEnv = pkgs.symlinkJoin {
    pname = "vscodium";
    version = pkgs.vscodium.version;
    paths = [ pkgs.vscodium ];
    postBuild = ''
      rm -f "$out/bin/codium"
      cat > "$out/bin/codium" <<'EOF'
      #!${pkgs.bash}/bin/bash
      if [ -f "${config.sops.secrets.anthropic-auth-token.path}" ]; then
        export ANTHROPIC_AUTH_TOKEN="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.anthropic-auth-token.path})"
      fi
      exec ${pkgs.vscodium}/bin/codium "$@"
      EOF
      chmod +x "$out/bin/codium"
    '';
  };
in
{
  options.home-manager.editor.vscode.enable = lib.mkEnableOption "vscode config" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.anthropic-auth-token.path = "${config.xdg.configHome}/secrets/anthropic-auth-token";

    programs.vscode = {
      enable = true;
      package = vscodiumWithAnthropicEnv;
      mutableExtensionsDir = false;

      profiles.default = {
        enableMcpIntegration = true;

        extensions =
          (with pkgs.vscode-extensions; [
            arcticicestudio.nord-visual-studio-code
            jnoortheen.nix-ide
            vscodevim.vim
          ])
          ++ [
            claudeCodeExtension
            pencilExtension
          ];

        userSettings = {
          "claudeCode.environmentVariables" = [
            {
              name = "ANTHROPIC_BASE_URL";
              value = anthropicBaseUrl;
            }
          ];
          "claudeCode.allowDangerouslySkipPermissions" = true;
          "claudeCode.initialPermissionMode" = "bypassPermissions";

          "workbench.colorTheme" = "Nord";
          "workbench.editor.openSideBySideDirection" = "right";

          "editor.lineNumbers" = "on";
          "editor.tabSize" = 4;
          "editor.insertSpaces" = true;
          "editor.formatOnSave" = true;

          "chat.mcp.discovery.enabled" = true;

          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "nix.serverSettings" = {
            nil = {
              formatting = {
                command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
              };
            };
          };

          "vim.useSystemClipboard" = true;
          "vim.useCtrlKeys" = true;
          "vim.leader" = "<space>";
          "vim.handleKeys" = {
            "<C-b>" = true;
            "<C-h>" = true;
            "<C-l>" = true;
          };
          "vim.surround" = true;

          "vim.normalModeKeyBindingsNonRecursive" = [
            {
              before = [ "<C-l>" ];
              commands = [ "workbench.action.nextEditorInGroup" ];
            }
            {
              before = [ "<C-h>" ];
              commands = [ "workbench.action.previousEditorInGroup" ];
            }
            {
              before = [
                "<leader>"
                "b"
                "d"
              ];
              commands = [ "workbench.action.closeActiveEditor" ];
            }
            {
              before = [
                "<tab>"
                "m"
                "p"
              ];
              commands = [ "markdown.showPreview" ];
            }
            {
              before = [
                "]"
                "d"
              ];
              commands = [ "editor.action.marker.next" ];
            }
            {
              before = [
                "["
                "d"
              ];
              commands = [ "editor.action.marker.prev" ];
            }
            {
              before = [
                "<leader>"
                "l"
                "g"
              ];
              commands = [
                "workbench.action.terminal.toggleTerminal"
                {
                  command = "workbench.action.terminal.sendSequence";
                  args = {
                    text = "lazygit\r";
                  };
                }
              ];
            }
            {
              before = [
                "<leader>"
                "g"
                "p"
              ];
              commands = [ "editor.action.dirtydiff.next" ];
            }
            {
              before = [
                "<leader>"
                "g"
                "r"
                "h"
              ];
              commands = [ "git.revertSelectedRanges" ];
            }
            {
              before = [
                "<tab>"
                "<space>"
                "f"
              ];
              commands = [ "workbench.action.quickOpen" ];
            }
            {
              before = [
                "<tab>"
                "<space>"
                "g"
              ];
              commands = [ "workbench.action.findInFiles" ];
            }
            {
              before = [
                "<tab>"
                "<space>"
                "l"
                "g"
              ];
              commands = [
                {
                  command = "workbench.action.findInFiles";
                  args = {
                    isRegex = false;
                  };
                }
              ];
            }
            {
              before = [
                "<leader>"
                "a"
              ];
              commands = [ "workbench.action.showWelcomePage" ];
            }
            {
              before = [ "<C-b>" ];
              commands = [ "workbench.action.toggleSidebarVisibility" ];
            }
          ];
        };
      };
    };
  };
}
