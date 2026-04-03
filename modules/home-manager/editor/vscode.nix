{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.editor.vscode;

  pencilExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "pencildev";
      publisher = "highagency";
      version = "0.6.38";
    };
    sha256 = "sha256-SpmKjxBttOdMCrPCxvXp93ZnS+UAd0vRxAOx0BSKIuc=";
  };
in
{
  options.home-manager.editor.vscode.enable = lib.mkEnableOption "vscode config" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = false;

      profiles.default = {
        enableMcpIntegration = true;

        extensions =
          (with pkgs.vscode-extensions; [
            arcticicestudio.nord-visual-studio-code
            jnoortheen.nix-ide
            vscodevim.vim
          ])
          ++ [ pencilExtension ];

        userSettings = {
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
