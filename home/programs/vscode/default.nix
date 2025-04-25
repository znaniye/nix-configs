{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    mutableExtensionsDir = false;

    profiles.default = {
      userSettings = {
        # — DotNet SDKs —
        "csharp.toolsDotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
        "dotnetAcquisitionExtension.sharedExistingDotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
        "dotnetAcquisitionExtension.existingDotnetPath" = [
          {
            extensionId = "ms-dotnettools.csharp";
            path = "${pkgs.dotnet-sdk_9}/bin/dotnet";
          }
          {
            extensionId = "ms-dotnettools.csdevkit";
            path = "${pkgs.dotnet-sdk_9}/bin/dotnet";
          }
          {
            extensionId = "woberg.godot-dotnet-tools";
            path = "${pkgs.dotnet-sdk_8}/bin/dotnet";
          }
        ];

        # — OmniSharp  —
        "omnisharp.path" = "${pkgs.omnisharp-roslyn}/bin/OmniSharp";
        "omnisharp.sdkPath" = "${pkgs.dotnet-sdk_9}/share/dotnet";
        "omnisharp.dotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
        "omnisharp.useGlobalMono" = "always";

        # — Godot Tools LSP —
        "godotTools.lsp.serverPort" = 6005;

        # — Editor stuff —
        "editor.codeLens" = false;
        "editor.fontFamily" = "Iosevka Nerd Font";
        "editor.fontWeight" = "bold";
        "editor.fontSize" = 18;
        "editor.acceptSuggestionOnCommitCharacter" = false;
        "terminal.integrated.fontFamily" = "Iosevka Nerd Font";
        "[nix]\"editor.tabSize\"" = 2;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "git.confirmSync" = false;
        "editor.minimap.enabled" = false;
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.colorTheme" = "Gruvbox Dark Hard";
        "window.menuBarVisibility" = "toggle";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "files.exclude" = {
          "**/*.gd.uid" = true;
          "**/*.cs.uid" = true;
        };
      };

      extensions = with pkgs.vscode-extensions; [
        jdinhlife.gruvbox
        pkief.material-icon-theme
        vscodevim.vim
        jnoortheen.nix-ide
        geequlim.godot-tools
        woberg.godot-dotnet-tools
        ms-dotnettools.csdevkit
        ms-dotnettools.csharp
        ms-dotnettools.vscode-dotnet-runtime
      ];
    };
  };
}
