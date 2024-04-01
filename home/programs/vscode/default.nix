{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      jdinhlife.gruvbox
      pkief.material-icon-theme
      vscodevim.vim

      elixir-lsp.vscode-elixir-ls
      phoenixframework.phoenix
      ms-python.python
      jnoortheen.nix-ide
      golang.go
    ];

    userSettings = {
      "editor.fontFamily" = "Iosevka Nerd Font";
      "editor.fontWeight" = "bold";
      "terminal.integrated.fontFamily" = "Iosevka Nerd Font";
      "[nix]"."editor.tabSize" = 2;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";

      "editor.fontSize" = 18;
      "git.confirmSync" = false;
      "editor.minimap.enabled" = false;
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.colorTheme" = "Gruvbox Dark Hard";
      "window.menuBarVisibility" = "toggle";
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
    };
  };
}
