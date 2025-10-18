(require 'package)
(add-to-list
 'package-archives
 '("melpa-stable" . "https://stable.melpa.org/packages/") t)

(package-initialize)
(require 'use-package)

(setq custom-file "~/.emacs.d/emacs-custom.el")

(use-package eldoc
  :config
  (setq eldoc-echo-area-prefer-doc-buffer t
	eldoc-echo-area-use-multiline-p 5))

;; This is builtin to Emacs 30, prior to that, it uses
;; https://github.com/justbur/emacs-which-key
(use-package which-key
  :ensure t
  :config
  (which-key-mode))

(use-package vertico
  :ensure t
  :config
  (vertico-mode 1)
  (setq read-file-name-completion-ignore-case t
	read-buffer-completion-ignore-base t
	completion-ignore-case t))

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(basic orderless))
  (setq completion-category-overrides '((ifle (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode 1))

;; builtin
(use-package savehist
  :config
  (setq history-length 100)
  (savehist-mode 1))

(use-package consult
  :ensure t
  :bind
  (;; C-c bindings (mode-specific-map)
   ("C-c h" . consult-history)
   ("C-c m" . consult-mode-command)
   ("C-c k" . consult-kmacro)
   ("C-c g" . consult-grep)
   ;; C-x bindings (ctl-x-map)
   ("C-x M-:" . consult-complex-command)

   ;; buffer ops
   ("C-x b" . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x 5 b" . consult-buffer-other-frame)
   ("C-x r b" . consult-bookmark)
   ("C-x p b" . consult-project-buffer)
   ("C-x p g" . consult-ripgrep)register access
   ;; register ops
   ("M-#" . consult-register-load)
   ("M-'" . consult-register-store)
   ("C-M-#" . consult-register)
   ;; Other custom bindings
   ("M-y" . consult-yank-pop)

   ;; M-g bindings (goto-map)
   ("M-g e" . consult-compile-error)
   ("M-g f" . consult-flymake)
   ("M-g g" . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-g o" . consult-outline)
   ("M-g m" . consult-mark)
   ("M-g k" . consult-global-mark)
   ("M-g i" . consult-imenu)
   ("M-g I" . consult-imenu-multi)
   ;; M-s bindings (search-map)
   ("M-s d" . consult-find)
   ("M-s D" . consult-locate)
   ("M-s g" . consult-grep)
   ("M-s G" . consult-git-grep)
   ("M-s r" . consult-ripgrep)
   ("M-s l" . consult-line)
   ("M-s L" . consult-line-multi)
   ("M-s k" . consult-keep-lines)
   ("M-s u" . consult-focus-lines)
   ;; Isearch integration
   ("M-s e" . consult-isearch-history)
   :map isearch-mode-map
   ("M-e" . consult-isearch-history)
   ("M-s e" . consult-isearch-history)
   ("M-s l" . consult-line)
   ("M-s L" . consult-line-multi)
   ;; Minibuffer history
   :map minibuffer-local-map
   ("M-s" . consult-history)
   ("M-r" . consult-history))

  :hook (completion-list-mode . consult-preview-at-point-mode)

  :config
  (setq register-preview-delay 0.5
	register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
	xref-show-definitions-function #'consult-xref)
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.4 any))

  (setq consult-narrow-key "<")
  )
