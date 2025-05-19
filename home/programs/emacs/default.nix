{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;

    extraPackages = epkgs: [
      epkgs.slime
      epkgs.paredit
      epkgs.rainbow-delimiters
    ];

    extraConfig = ''
      ;;; UI
      (when (display-graphic-p)
        (tool-bar-mode -1)
        (scroll-bar-mode -1)
        (menu-bar-mode -1))
      (setq inhibit-startup-screen t)

      (load-theme 'wombat t)
      (set-face-background 'default "#111")

      (setq-default indent-tabs-mode nil)

      ;;; Parentheses matching
      (setq show-paren-delay 0)
      (show-paren-mode)

      ;;; Custom file
      (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
      (load custom-file t)

      ;;; SLIME config
      (setq inferior-lisp-program "${pkgs.sbcl}/bin/sbcl")

      ;;; Paredit
      (require 'paredit)
      (dolist (hook '(emacs-lisp-mode-hook
                      eval-expression-minibuffer-setup-hook
                      ielm-mode-hook
                      lisp-interaction-mode-hook
                      lisp-mode-hook
                      slime-repl-mode-hook))
        (add-hook hook 'enable-paredit-mode))

      (defun override-slime-del-key ()
        (define-key slime-repl-mode-map
          (read-kbd-macro paredit-backward-delete-key) nil))
      (add-hook 'slime-repl-mode-hook 'override-slime-del-key)

      ;;; Rainbow Delimiters
      (require 'rainbow-delimiters)
      (dolist (hook '(emacs-lisp-mode-hook
                      ielm-mode-hook
                      lisp-interaction-mode-hook
                      lisp-mode-hook
                      slime-repl-mode-hook))
        (add-hook hook 'rainbow-delimiters-mode))

      ;;color
      (set-face-foreground 'rainbow-delimiters-depth-1-face "#c66")
      (set-face-foreground 'rainbow-delimiters-depth-2-face "#6c6")
      (set-face-foreground 'rainbow-delimiters-depth-3-face "#69f")
      (set-face-foreground 'rainbow-delimiters-depth-4-face "#cc6")
      (set-face-foreground 'rainbow-delimiters-depth-5-face "#6cc")
      (set-face-foreground 'rainbow-delimiters-depth-6-face "#c6c")
      (set-face-foreground 'rainbow-delimiters-depth-7-face "#ccc")
      (set-face-foreground 'rainbow-delimiters-depth-8-face "#999")
      (set-face-foreground 'rainbow-delimiters-depth-9-face "#666")
    '';
  };
}
