;;; ipynb.el --- Render Jupyter notebook files (ipynb) -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Przemyslaw Kryger

;; Author: Przemyslaw Kryger <pkryger@gmail.com>
;; Keywords: tools jupyter notebook
;; Homepage: https://github.com/pkryger/ipynb.el
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.0.0


;;; Commentary:
;;
;; The =ipynb= Emacs package is designed to render (and browse) Jupyter
;; notebook .ipynb files from the confines of Emacs.  Such a functionality is
;; useful, for example when reviewing a pull request with .ipynb files
;; included.
;;
;; You need jupterlab installed on your system, for example type something like:
;;   brew install jupyterlab
;;
;; Jupyter notebooks can be rendered inside Emacs with either
;; `ipynb-find-and-render-file' or `ipynb-render-buffer'.  Alternatively, they
;; can be browsed in a system Web browser with either
;; `ipynb-find-and-browse-file' or `ipynb-browse-buffer'.

;;; Code:
(eval-when-compile
  (require 'cl-lib))
(declare-function shr-render-buffer "shr" (buffer))

(defvar ipynb--convert-command
  "jupyter nbconvert --to html --log-level WARN --stdout --stdin")

(defvar ipynb--in-or-out-regexp
  (rx-to-string
   '(seq line-start
         (or "In" "Out")
         (zero-or-more space)
         "["
         (one-or-more digit)
         "]:"
         line-end)))

(defun ipynb--next-in-or-out ()
  "Find line beginning position of next In or Out."
  (save-excursion
    (goto-char (line-end-position))
    (when (re-search-forward ipynb--in-or-out-regexp nil t)
      (line-beginning-position))))

(defun ipynb--prev-in-or-out ()
  "Find line beginning position of previous In or Out."
  (save-excursion
    (goto-char (line-beginning-position))
    (backward-char)
    (cl-block searching-prev-chunk
      (when (re-search-backward ipynb--in-or-out-regexp nil t)
        (line-beginning-position)))))

(defun ipynb-next-in-or-out ()
  "Move to the next file."
  (interactive nil ipynb-render-mode)
  (if-let* ((next (ipynb--next-in-or-out)))
      (goto-char next)
    (user-error "No more In nor Out")))

(defun ipynb-previous-in-or-out ()
  "Move to the previous file."
  (interactive nil ipynb-render-mode)
  (if-let* ((previous (ipynb--prev-in-or-out)))
      (goto-char previous)
    (user-error "No more In nor Out")))

(defvar-keymap ipynb-render-mode-map
  :doc "Keymap for `ipynb-mode'."
  "N"     #'ipynb-next-in-or-out
  "P"     #'ipynb-previous-in-or-out)

;;;###autoload
(define-derived-mode ipynb-render-mode fundamental-mode "ipynb-render"
  "Major mode to display output of rendered ipynb files."
  (view-mode)
  (setq buffer-read-only t))

;;;###autoload
(defun ipynb-find-and-render-file (file-name)
  "Find FILE-NAME and open is as html."
  (interactive
   (list (read-file-name "Find ipynb file to render: " nil nil t)))
  (let ((base-name (file-name-nondirectory file-name)))
    (with-temp-buffer
      (insert-file-contents file-name)
      (shell-command-on-region (point-min)
                               (point-max)
                               ipynb--convert-command
                               nil
                               'no-mark)
      (shr-render-buffer (current-buffer)))
    (with-current-buffer "*html*"
      (rename-buffer (format "*%s<render>*" base-name) 'unique)
      (ipynb-render-mode))))

;;;###autoload
(defun ipynb-render-buffer (buffer)
  "Render ipynb BUFFER as html."
  (interactive
   (list (read-buffer "ipynb buffer to render: " (current-buffer) t)))
  (let ((buffer-name (buffer-name)))
    (with-temp-buffer
      (insert-buffer-substring (get-buffer buffer))
      (shell-command-on-region (point-min)
                               (point-max)
                               ipynb--convert-command
                               nil
                               'no-mark)
      (shr-render-buffer (current-buffer)))
    (with-current-buffer "*html*"
      (rename-buffer (format "*%s<render>*" buffer-name) 'unique)
      (ipynb-render-mode))))

;;;###autoload
(defun ipynb-find-and-browse-file (file-name)
  "Find FILE-NAME and open is as html."
  (interactive
   (list (read-file-name "Find ipynb file to browse: " nil nil t)))
  (with-temp-buffer
    (insert-file-contents file-name)
    (shell-command-on-region (point-min)
                             (point-max)
                             ipynb--convert-command
                             nil
                             'no-mark)
    (browse-url-of-buffer)))

;;;###autoload
(defun ipynb-browse-buffer (buffer)
  "Render ipynb BUFFER as html."
  (interactive
   (list (read-buffer "ipynb buffer to browse: " (current-buffer) t)))
  (with-temp-buffer
    (insert-buffer-substring (get-buffer buffer))
    (shell-command-on-region (point-min)
                             (point-max)
                             ipynb--convert-command
                             nil
                             'no-mark)
    (browse-url-of-buffer)))

(provide 'ipynb)

;;; ipynb.el ends here
