;;;
;;; Set up package manager and use-package
;;;

(package-initialize)

(require 'use-package)
(setq use-package-always-defer t)


;; Internal modes
(require 'calendar)
(require 'display-line-numbers)


;;;
;;; General configuration
;;;

(setq
 ;; Disable creation of lock-files named .#<filaname>
 create-lockfiles nil

 ;; Paste at point, not at cursor
 mouse-yank-at-point t

 ;; Weeks starts on Mondays
 calendar-week-start-day 1

 ;; Change all yes-or-no-p to y-or-n-p
 use-short-answers t)


;; Slow things to load after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            ;; Auto reread from disk when file changes
            (global-auto-revert-mode t)

            ;; Enable Winner Mode
            (winner-mode 1)

            ;; Disable line wrapping where the window ends
            (toggle-truncate-lines t)

            ;; Hide menubar, toolbar and scrollbar
            (menu-bar-mode -1)
            (tool-bar-mode -1)
            (if (boundp 'scroll-bar-mode)
                (scroll-bar-mode -1))

            ;; Highlight parenthesises
            (show-paren-mode t)

            ;; Disable the cursor blink
            (blink-cursor-mode 0)

            ;; Enable column number together with line numbers
            (column-number-mode t)))

(use-package nord-theme
  :ensure t
  :demand t
  :config (load-theme 'nord t))


(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

;; Languages

;; Nix mode
(use-package nix-mode
  :ensure t
  :mode "\\.nix$"
  :init (setq nix-indent-function 'nix-indent-line))


;; Utilities

;; Magit
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)     ; Display the main magit popup
  :init (setq magit-log-arguments
              '("--graph" "--color" "--decorate" "--show-signature" "-n256")))
