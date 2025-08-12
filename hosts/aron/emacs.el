;;; Init.el ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Here we initialize use package and add the usual melpa repositories
(require 'package)
(add-to-list 'package-archives '("gnu"   . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
	     '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure t
        use-package-expand-minimally t))

;; Initliaize Quelpa
(unless (package-installed-p 'quelpa)
  (with-temp-buffer
    (url-insert-file-contents "https://raw.githubusercontent.com/quelpa/quelpa/master/quelpa.el")
    (eval-buffer)
    (quelpa-self-upgrade)))

(use-package emacs
  :config
  ;; Set the Terminus font and font size
  (set-face-attribute 'default nil :font "Hack 15")

  (setq tab-always-indent 'complete)
  (defalias 'yes-or-no-p 'y-or-n-p) ;; life is too short
  (setq indent-tabs-mode nil) ;; no tabs

  ;; keep backup and save files in a dedicated directory
  (setq backup-directory-alist
          `((".*" . ,(concat user-emacs-directory "backups")))
          auto-save-file-name-transforms
          `((".*" ,(concat user-emacs-directory "backups") t)))
  (menu-bar-mode t)
  (line-number-mode 1)
  (scroll-bar-mode -1)
  (tool-bar-mode -1))

(use-package modus-themes)
(use-package catppuccin-theme)
(load-theme 'catppuccin :no-confirm)

;; Eat is an eshell alternative
(use-package eat)

;; Bunch of dired utilities
(use-package dired-hacks-utils)

;; here we have all the language modelines
(use-package typescript-mode
  :mode ("\\.tsx?\\'" . typescript-mode)
  :config
  (setq typescript-indent-level 2))

(use-package go-mode
  :mode ("\\.go?\\'" . go-mode))

(use-package bison-mode
  :mode ("\\.l?\\'" . bison-mode))

(use-package rust-mode
  :mode ("\\.rs?\\'" . rust-mode))

(use-package nix-mode
  :mode ("\\.nix?\\'" . nix-mode))

(use-package zig-mode
  :mode ("\\.zig?\\'" . zig-mode))

(use-package python-mode
  :mode ("\\.py?\\'" . python-mode))

(use-package markdown-mode
  :mode ("\\.md?\\'" . markdown-mode))

(use-package envrc
  :hook (after-init . envrc-global-mode))

;; LSP stuff
(use-package eglot
  :init (setq completion-category-overrides '((eglot (styles orderless))))
  :config
  (add-to-list 'eglot-server-programs
               `(rust-mode . ("rust-analyzer" :initializationOptions
                              ( :procMacro (:enable t)
                                :cargo ( :buildScripts (:enable t)
                                         :features "all"))))))

;; mode that helps with the undos
(use-package vundo)

(use-package ibuffer
    :ensure nil
    :bind (("C-x C-b" . ibuffer)))

(use-package bufler
  :bind
  (("C-x C-b" . bufler-list)
    ("C-x b" . bufler-switch-buffer)))

(use-package marginalia
  :custom
  (marginalia-max-relative-age 0)
  (marginalia-align 'right)
  :init
  (marginalia-mode))

(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))

(use-package vertico
  :custom
  (vertico-count 13)  ; Number of candidates to display
  (vertico-resize t)
  (vertico-cycle nil) ; Go from last to first candidate and first to last (cycle)?
  ;; :general
  ;; (:keymaps 'vertico-map
  ;;  "<tab>" #'vertico-insert  ; Insert selected candidate into text area
  ;;  "<escape>" #'minibuffer-keyboard-quit ; Close minibuffer
  ;;  ;; NOTE 2022-02-05: Cycle through candidate groups
  ;;  "C-M-n" #'vertico-next-group
  ;;  "C-M-p" #'vertico-previous-group)
  :config
  (vertico-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless))      ; Use orderless
  (completion-category-defaults nil))
;  (completion-category-overrides '((eglot (styles . (orderless flex))))))
;;  (completion-category-overrides
;; '((file (styles basic-remote ; For `tramp' hostname completion with `vertico'
;;                   orderless)))))

(use-package corfu
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-auto t)                 ;; Enable auto completion
  ;; (corfu-separator ?\s)          ;; Orderless field separator
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin
  :init
  (global-corfu-mode))

(use-package consult
  :bind
  ("C-s" . consult-line))

(use-package magit)

(use-package moody
  :config
  (setq x-underline-at-descent-line t)
  (moody-replace-eldoc-minibuffer-message-function))

(use-package minions)

(use-package envrc
  :init
  (envrc-global-mode))

(use-package direnv
  :config (direnv-mode))

(use-package kubernetes)
;; (use-package dockerfile-mode)
(use-package jsonnet-mode)
(use-package terraform-mode)
(use-package yaml-mode)
(use-package json-mode)

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

(use-package eyebrowse)
(use-package shackle)

(use-package treesit-auto
  :config
  (global-treesit-auto-mode))

(use-package php-mode
  :mode ("\\.php?\\'" . php-mode))

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; GTD Setup
(setq org-todo-keywords
      '((sequence "TODO(t)" "WAIT(w)" "NEXT(n)" "PROJ(p)" "|" "DONE(d)" "CANC(c)")
        ))

(setq org-agenda-span 90)
(setq org-agenda-files (file-expand-wildcards "~/env/org/main.org"))

(setq org-agenda-custom-commands
      '(
        ("i" "Inbox" tags-todo "+TODO=\"TODO\""
         ((org-agenda-files (file-expand-wildcards "~/env/org/inbox.org"))))
        ("n" "Next actions" tags-todo "+TODO=\"NEXT\"")
        ("p" "Projects" tags-todo "+TODO=\"PROJ\"")
        ("w" "Waiting" tags-todo "+TODO=\"WAIT\"")
        ("s" "Someday" tags-todo "+TODO=\"TODO\"|TODO=\"PROJ\""
         ((org-agenda-files (file-expand-wildcards "~/env/org/someday.org"))))
        ("o" "Actions and Projects" tags-todo "+TODO=\"TODO\"|TODO=\"PROJ\"")
        ))

(setq org-agenda-prefix-format '((agenda . "  %-25:c%?-12t% s")
				 (timeline . "  % s")
				 (todo . "  %-12:c")
				 (tags . "  %-25:c")
				 (search . "  %-12:c")))

(setq org-agenda-tags-column -120)
(setq org-tags-column -80)

(setq org-agenda-sorting-strategy
      '((agenda habit-down time-up priority-down category-keep)
        (todo priority-down todo-state-up category-keep)
        (tags priority-down todo-state-up category-keep)
        (search category-keep)))

;; M-x org-agenda # to show the stuck projects
(setq org-stuck-projects
      '("+TODO=\"PROJ\"" ("TODO") nil "") )

(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps 'nil)
(setq refile-targets (file-expand-wildcards "~/env/org/*.org"))
(setq org-refile-targets '(( refile-targets :todo . "PROJ" )))

(setq org-capture-templates
      '(
        ("i" "Inbox" entry
         (file "~/env/org/inbox.org")
         "* TODO %^{Brief Description}\nAdded: %U\n%?" :empty-lines 1 :prepend t)

        ("n" "Next action" entry
         (file "~/env/org/main.org")
         "** NEXT %^{Brief Description}\nAdded: %U\n%?" :empty-lines 1 :prepend t)

        ("w" "Waiting" entry
         (file "~/env/org/main.org")
         "** WAIT %^{Brief Description}\nAdded: %U\n%?" :empty-lines 1 :prepend t)

        ("p" "Project" entry
         (file "~/env/org/main.org")
         "* PROJ %^{Brief Description}\n:PROPERTIES:\n:CATEGORY: %^{Id}\n:END:\nAdded: %U\n%?" :empty-lines 1 :prepend t)

         ("s" "Someday" entry
         (file "~/env/org/someday.org")
         "* TODO %^{Brief Description}\nAdded: %U\n%?" :empty-lines 1 :prepend t)
        ))

(define-key global-map "\C-cc" 'org-capture)

(quelpa '(quelpa-use-package
 :fetcher git
 :url "https://github.com/quelpa/quelpa-use-package.git"))

(use-package smerge-mode
  :ensure nil
  :hook
  (prog-mode . smerge-mode))

(use-package vterm)
(use-package kubel
  :after (vterm)
  :config (kubel-vterm-setup))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell . t)))

(add-hook 'org-mode-hook #'org-shortcut-mode nil nil)
(setq org-shortcut-state-alist
      '(("TODO"    . "To Do")
	("BACKLOG" . "Backlog")
        ("ACTIVE"  . "Doing")
	("WAIT"    . "In review")
        ("DONE"    . "Done")))


;; Hledger setup
(use-package hledger-mode
  :config
  (setq hledger-jfile "~/env/finance/2024.journal")
  :mode ("\\.journal\\'" "\\.hledger\\'"))

(use-package ledger-mode
  :config
  (setq ledger-mode-should-check-version nil
	ledger-report-links-in-register nil
        ledger-report-auto-width nil
        ledger-report-native-highlighting-arguments '("--color=always")
        ledger-highlight-xact-under-point nil
        ;; ledger-default-date-format ledger-iso-date-format
	ledger-binary-path "/etc/profiles/per-user/marco/bin/ledger")
  :mode ("\\.journal\\'" "\\.ledger\\'"))

;; Custom stuff
(use-package dwim-shell-command
  :bind (([remap shell-command] . dwim-shell-command)
         :map dired-mode-map
         ([remap dired-do-async-shell-command] . dwim-shell-command)
         ([remap dired-do-shell-command] . dwim-shell-command)
         ([remap dired-smart-shell-command] . dwim-shell-command))
  :config
  (defun my/dwim-shell-command-convert-to-gif ()
    "Convert all marked videos to optimized gif(s)."
    (interactive)
    (dwim-shell-command-on-marked-files
     "Convert to gif"
     "ffmpeg -loglevel quiet -stats -y -i '<<f>>' -pix_fmt rgb24 -r 15 '<<fne>>.gif'"
     :utils "ffmpeg"))
  (defun dwim-shell-commands-macos-toggle-menu-bar-autohide ()
    "Toggle macOS menu bar auto-hide."
    (interactive)
    (dwim-shell-command-on-marked-files
     "Toggle menu bar auto-hide."
     "current_status=$(osascript -e 'tell application \"System Events\" to get autohide menu bar of dock preferences')

if [ \"$current_status\" = \"true\" ]; then
    osascript -e 'tell application \"System Events\" to set autohide menu bar of dock preferences to false'
    echo \"Auto-hide disabled.\"
else
    osascript -e 'tell application \"System Events\" to set autohide menu bar of dock preferences to true'
    echo \"Auto-hide enabled.\"
fi"
     :utils "osascript"
     :silent-success t)))

(use-package olivetti)

(defun meow-setup ()
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-motion-overwrite-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("<escape>" . ignore))
  (meow-leader-define-key
   ;; SPC j/k will run the original command in MOTION state.
   '("j" . "H-j")
   '("k" . "H-k")
   ;; Use SPC (0-9) for digit arguments.
   '("1" . meow-digit-argument)
   '("2" . meow-digit-argument)
   '("3" . meow-digit-argument)
   '("4" . meow-digit-argument)
   '("5" . meow-digit-argument)
   '("6" . meow-digit-argument)
   '("7" . meow-digit-argument)
   '("8" . meow-digit-argument)
   '("9" . meow-digit-argument)
   '("0" . meow-digit-argument)
   '("/" . meow-keypad-describe-key)
   '("?" . meow-cheatsheet))
  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . meow-find)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("m" . meow-join)
   '("n" . meow-search)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-visit)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore)))

(use-package meow)
(meow-setup)
(meow-global-mode 1)

(use-package kubernetes)

(use-package ace-window
  :bind ("M-o" . ace-window))
