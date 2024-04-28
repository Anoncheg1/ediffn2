;;; ediffnw.el --- In Ediff, get rid of control window and rebind keys  -*- lexical-binding: t -*-

;; Copyright (c) 2024 github.com/Anoncheg1,codeberg.org/Anoncheg

;; Author: github.com/Anoncheg1,codeberg.org/Anoncheg
;; Keywords:  comparing, merging, patching, vc, tools, unix
;; URL: https://codeberg.org/Anoncheg/diffnw
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.3"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Allow to execute Ediff commands in "variants" A, B windows without
;; necessity to select control frame.  A,B,C is not supported for now.

;; Activation:
;; 1) Execute M-x ediffnw RET
;; 2) $ emacs --eval "(ediff \"/file1\" \"/file2\" )"

;; Customization:

;; M-x customize-variable RET ediffnw-purge-window RET

;; How it works:

;; We save control buffer in buffer local variables of A, B variants
;; and run minor-mode with wrapped functions that switching to control
;; buffer automatically to call original functions.

;;; Code:
(require 'ediff)
(require 'ediff-wind)

(defvar-local ediffnw-control-buffer nil)

(defgroup ediffnw nil
  "Ediff without control window."
  :group 'ediffnw
  :prefix "firstly-search-")

(defcustom ediffnw-purge-window nil
  "Non-nil means remove window completely.
Change `ediff-window-setup-function' global variable, that affect
ediff globally."
  :local nil
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value ; TODO: check symbol is ediffnw-purge-window
             (setopt ediff-window-setup-function #'ediff-setup-windows-plain)))
  :type '(boolean)
  :group 'ediffnw)


(defmacro ediffnw--macro (fun)
  "Create wrap functions for Ediff with prefix: ediffnw-.
Wrap function uses saved control buffer and execute function
inside of it, after return
Argument FUN function that will be wrapped."
  (let ((command-name (intern (format "ediffnw-%s" fun))))
  `(defun ,command-name ()
     (interactive)
     (if (and (display-graphic-p)
              (or (eq ediff-window-setup-function #'ediff-setup-windows-default)
                  (eq ediff-window-setup-function #'ediff-setup-windows-multiframe)))
         (progn
           (with-current-buffer ediffnw-control-buffer
             (call-interactively #',fun))
           ;; fix frame selection
           (raise-frame (next-frame)))

       ;; else - control buffer is separate window
       (let ((cb (current-buffer)))
         (switch-to-buffer ediffnw-control-buffer t t)
         (call-interactively #',fun)
         (switch-to-buffer cb))
       (if ediffnw-purge-window
           (delete-window (get-buffer-window ediffnw-control-buffer)))))))

;; Wrap functions with "ediffnw-" prefix
(ediffnw--macro ediff-previous-difference)
(ediffnw--macro ediff-next-difference)
(ediffnw--macro ediff-quit)
(ediffnw--macro ediff-toggle-split)
(ediffnw--macro ediff-toggle-hilit)
(ediffnw--macro ediff-toggle-autorefine)
(ediffnw--macro ediff-toggle-narrow-region)
(ediffnw--macro ediff-update-diffs)
(ediffnw--macro ediff-combine-diffs)
(ediffnw--macro ediff-copy-A-to-B)
(ediffnw--macro ediff-copy-B-to-A)
(ediffnw--macro ediff-toggle-read-only)
(ediffnw--macro ediff-recenter)
(ediffnw--macro ediff-swap-buffers)
(ediffnw--macro ediff-show-current-session-meta-buffer)
(ediffnw--macro ediff-show-registry)
(ediffnw--macro ediff-save-buffer)
(ediffnw--macro ediff-inferior-compare-regions)
(ediffnw--macro ediff-toggle-wide-display)

;; (global-set-key (kbd "C-M-") (lambda ()(interactive) (print "asd")))
(defvar-keymap ediffnw-mode-map
  :doc "Replacement for `ediff-setup-keymap'."
  ;; :parent firstly-search-tabulated-list-mode-map
  "C-M-k"	#'ediffnw-ediff-previous-difference
  "C-M-n"	#'ediffnw-ediff-next-difference
  "C-M-q"	#'ediffnw-ediff-quit
  "C-|"	#'ediffnw-ediff-toggle-split
  "C-M-h"	#'ediffnw-ediff-toggle-hilit
  "C-@"	#'ediffnw-ediff-toggle-autorefine
  "C-%"	#'ediffnw-ediff-toggle-narrow-region
  "C-!"	#'ediffnw-ediff-update-diffs
  "C-+"	#'ediffnw-ediff-combine-diffs
  "C-M-a"	#'ediffnw-ediff-copy-A-to-B
  "C-M-b"	#'ediffnw-ediff-copy-B-to-A
  "C-M-t"	#'ediffnw-ediff-toggle-read-only
  "C-M-l"	#'ediffnw-ediff-recenter
  "C-M-~"	#'ediffnw-ediff-swap-buffers
  "C-M-M"	#'ediffnw-ediff-show-current-session-meta-buffer
  "C-M-R"	#'ediffnw-ediff-show-registry
  "C-M-w"	#'ediffnw-ediff-save-buffer
  "C-="	#'ediffnw-ediff-inferior-compare-regions
  "C-M-m"	#'ediffnw-ediff-toggle-wide-display)

;;;###autoload
(define-minor-mode ediffnw-mode
  "Activated in A, B windows and provide Ediff rebinded keys."
  :lighter " ediff"
  :global nil)

(defvar ediffnw--ediffnw-control-buffer nil
"Temp variable that used only to set `ediffnw-control-buffer'.")

(defun ediffnw--startup()
  "Save control buffer in `buffer-local' variables of variants."
  ;; save to temporary value
  (setq ediffnw--ediffnw-control-buffer ediff-control-buffer)

  (with-current-buffer ediff-buffer-A
    ;; save in local-buffer value
    (setq ediffnw-control-buffer ediffnw--ediffnw-control-buffer)
    (ediffnw-mode))

  (with-current-buffer ediff-buffer-B
    ;; save in local-buffer value
    (setq ediffnw-control-buffer ediffnw--ediffnw-control-buffer)
    (ediffnw-mode)))

;;;###autoload
(defun ediffnw-files (file-a file-b)
  "Wrap `ediff-files' function with our initialization funcion.
Interactive behaviour may alter.
Argument FILE-A file A.
Argument FILE-B file B."
  (interactive)
  (ediff-files file-a file-b '(ediffnw--startup)))

;;;###autoload
(defalias 'ediffnw #'ediffnw-files)

(provide 'ediffnw)
;;; ediffnw.el ends here
