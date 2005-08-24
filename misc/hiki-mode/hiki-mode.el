;;; hiki-mode.el -- Major mode for Hiki editing -*- coding: euc-jp -*-

;; Copyright (C) 2003 Hideaki Hori

;; Author: Hideaki Hori <yowaken@cool.ne.jp>

;; $Id: hiki-mode.el,v 1.10 2005-08-24 06:43:04 fdiary Exp $
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; usage:
;;
;; Put the following in ~/.emacs or ~/.hiki
;;
;;  (setq hiki-site-list '(("my 1st Hiki" "http://example.com/hiki/hiki.cgi")
;;                         ("my 2nd Hiki" "http://example.com/hiki2/")))
;;  (setq hiki-browser-function 'browse-url)
;;  (autoload 'hiki-edit "hiki-mode" nil t)
;;  (autoload 'hiki-edit-url "hiki-mode" nil t)
;;

;;; Variable:
(require 'pces)

(defvar hiki-http-proxy-server nil "Proxy server for HTTP.")
(defvar hiki-http-proxy-port   nil "Proxy port for HTTP.")

(defvar hiki-http-timeout 10
  "Timeout for HTTP.")

(defvar hiki-http-cookie nil)

(defvar hiki-freeze nil)

(if (or (featurep 'xemacs) (not (boundp 'emacs-major-version)) (< emacs-major-version 21))
    (progn
      (require 'poe)
      (require 'poem)))
(require 'derived)

(defconst hiki-mode-version
  (let ((revision "$Revision: 1.10 $"))
    (string-match "\\([0-9.]+\\)" revision)
    (match-string 1 revision)))

(defvar hiki-site-list nil
  "List of Hiki list.
Each element looks like (NAME URL STYLE). STYLE is optional.")

(defvar hiki-list nil
  "`hiki-list' is OBSOLETE; use hiki-site-list.")

(defvar hiki-site-info nil)

(defvar hiki-index-page-info-list nil)

(defvar hiki-index-sort-key nil)

(defvar hiki-coding-system 'euc-japan-dos)

(defvar hiki-pagename nil)

(defvar hiki-pagetitle nil)

(defvar hiki-md5hex nil)

(defvar hiki-session-id nil)

(defvar hiki-update-timestamp nil)

(defvar hiki-edit-newpage nil)

(defvar hiki-password-alist nil)

(defvar hiki-browser-function nil
  "Function to call browser.
If non-nil, `hiki-edit-save-page' calls this function.  The function
is expected to accept only one argument(URL).")

(defvar hiki-init-file "~/.hiki"
  "Init file for hiki-mode.")

(defvar hiki-non-wikiname-regexp-string "[^A-Za-z0-9]")
(defvar hiki-wikiname-regexp-string "\\([A-Z][a-z0-9]+\\([A-Z][a-z0-9]+\\)+\\)")
(defvar hiki-wikiname-regexp-list
  (list
   (cons (concat hiki-non-wikiname-regexp-string hiki-wikiname-regexp-string hiki-non-wikiname-regexp-string) 1)
   (cons (concat "^" hiki-wikiname-regexp-string hiki-non-wikiname-regexp-string) 1)
   (cons (concat hiki-non-wikiname-regexp-string hiki-wikiname-regexp-string "$") 1)
   (cons (concat "^" hiki-wikiname-regexp-string "$") 1)))
(defvar hiki-bracket-name-regexp '("\\[\\[\\([^]:|]+\\)\\]\\]" . 1) )
(defvar hiki-rd+-bracket-name-regexp '("((<\\([^>:|]+\\)>))" . 1))

(defvar hiki-style-anchor-regexp-alist
  (list
   (cons 'default (cons hiki-bracket-name-regexp hiki-wikiname-regexp-list))
   (cons 'rd+ (list hiki-rd+-bracket-name-regexp)))
  "Alist of regexp for anchor.")

(defvar hiki-anchor-regexp-alist 
  (cdr (assoc 'default hiki-style-anchor-regexp-alist)))

(defvar hiki-anchor-face
  (copy-face 'underline 'hiki-anchor-face)
  "Face for Hiki anchor." )

(defvar hiki-site-name-history nil
  "History of Hiki site name." )

(defvar hiki-pagename-history nil
  "History of Hiki page name." )

(defvar hiki-diff-buffer-name "*Hiki diff*")

(defvar hiki-page-buffer-alist nil)

(defvar hiki-init nil)

;;; Code:

(defun hiki-mode-version ()
  (interactive)
  (message (format "hiki-mode (Revision: %s)" hiki-mode-version)))

(defun hiki-initialize ()
  (unless hiki-init
    (hiki-load-init-file)
    (setq hiki-init t)))

;;; 編集モード (hiki-edit-*)

(define-derived-mode hiki-edit-mode text-mode "Hiki Edit"
  "Major mode for Hiki editing.

\\{hiki-edit-mode-map}"
  (make-local-variable 'require-final-newline)	
  (make-local-variable 'hiki-site-info)
  (make-local-variable 'hiki-newpage)
  (make-local-variable 'hiki-pagename)
  (make-local-variable 'hiki-md5hex)
  (make-local-variable 'hiki-session-id)
  (make-local-variable 'hiki-update-timestamp)
  (setq require-final-newline t
	indent-tabs-mode nil)
  (hiki-edit-setup-keys)
  (set-buffer-file-coding-system hiki-coding-system)
  (setq hiki-anchor-regexp-alist
	(cdr (assoc (hiki-site-style hiki-site-info) hiki-style-anchor-regexp-alist)))

  (when (and (featurep 'font-lock) (fboundp 'font-lock-add-keywords))
    (let ((case-fold-search nil))
      ;;(font-lock-set-defaults)
      (font-lock-add-keywords 
       'hiki-edit-mode
       (mapcar (lambda (cell)
		 (list (car cell) (cdr cell) 'hiki-anchor-face t))
	       hiki-anchor-regexp-alist)))

    (put 'hiki-edit-mode 'font-lock-defaults '(text-font-lock-keywords nil t))
    (turn-on-font-lock))

  (run-hooks 'hiki-edit-mode-hook))

(defun hiki-edit-setup-keys ()
  "Set up keymap for hiki-edit-mode.
If you want to set up your own key bindings, use `hiki-edit-mode-hook'."
  (define-key hiki-edit-mode-map "\C-c\C-i" 'hiki-edit-next-anchor)
  (define-key hiki-edit-mode-map "\C-c\C-r" 'hiki-edit-reload)
  (define-key hiki-edit-mode-map "\C-c\C-e" 'hiki-edit)
  (define-key hiki-edit-mode-map "\C-c\C-c" 'hiki-edit-save-page)
  (define-key hiki-edit-mode-map "\C-c\C-q" 'hiki-edit-quit)
  )

(defun hiki-load-init-file ()
  "Load init file."
  (when hiki-init-file
    (let ((init-file (expand-file-name hiki-init-file)))
      (when (file-readable-p init-file)
	(load init-file t t))
      (hiki-obsolete-check))))

(defun hiki-obsolete-check ()
  (when hiki-list
    (message "hiki-list is OBSOLETE. Use hiki-site-list.")
    (sit-for 5)
    (setq hiki-site-list hiki-list)))

(defun hiki-read-site-name (&optional string)
  "サイト名をミニバッファから読み、サイト情報のリストを返す。

STRING が non-nil なら、それをサイト名とする。"
  (let* ((selected (car hiki-site-list))
	 (default (or (hiki-site-name) (car selected))))
    (assoc 
     (or 
      (completing-read (format "Select SITE (%s): " default) hiki-site-list 
		       nil t nil 'hiki-site-name-history default) default)
     hiki-site-list)))

(defun hiki-password-read (sitename pagename)
  (cdr (assoc (cons sitename pagename) hiki-password-alist)))

(defun hiki-password-store (sitename pagename password)
  (let (key unit)
    (setq key (cons sitename pagename)
	  unit (assoc key hiki-password-alist))
    (if unit
	(if password
	    (setcdr unit password)
	  (setq hiki-password-alist (delete unit hiki-password-alist)))
      (if password
	  (setq hiki-password-alist (cons (cons (cons sitename pagename) password) hiki-password-alist))))))

(defun hiki-read-pagename (arg site-name)
  (completing-read (format "Page name for %s: " site-name) 
		   (cdr (assoc site-name hiki-pagename-history)) 
		   nil nil arg nil arg))

;;; navi2ch-read-char を参考にしてます。
(defun hiki-read-char (prompt)
  "PROMPT (non-nil の場合) を表示して `read-char' を呼び出す。"
  (let ((cursor-in-echo-area t)
	c)
    (if prompt
	(message "%s" prompt))
    (setq c (read-char))
    (if prompt
	(message "%s%c" prompt c))
    c))

;;; navi2ch-read-char-with-retry を参考にしてます。
(defun hiki-read-char-with-retry (prompt retry-prompt list)
  (let ((retry t) c)
    (while retry
      (setq c (hiki-read-char prompt))
      (cond ((memq c list) (setq retry nil))
	    ((eq c 12) (recenter))
	    (t
	     (ding)
	     (setq prompt (or retry-prompt prompt)))))
    c))

(defun hiki-http-request (mode cmd pagename site-url &optional post-data)
  (let* ((url (if (eq mode 'get)
                  (concat (format "%s?c=%s" site-url cmd)
                          (if pagename 
                              (format ";p=%s" (hiki-http-url-hexify-string pagename hiki-coding-system))))
                site-url))
         (buf (hiki-http-fetch url mode nil nil 
                               (hiki-http-url-hexify-alist post-data hiki-coding-system))))
    (if (bufferp buf)
        (save-excursion
          (set-buffer buf)
          (decode-coding-region (point-min) (point-max) hiki-coding-system)
          (goto-char (point-min))
          buf)
      (error (format "hiki get: %s - %s" (car buf) (cdr buf))))))

(defun hiki-current-anchor-string ()
  "Return anchor string at current point."
  (let (str result pos (point (point)))
    (save-excursion
      (beginning-of-line)
      (setq pos (point))
      (while (and (setq result (hiki-search-anchor pos))
		  (<= (cdr result) point))
	(setq pos (cdr result)))
      (when (and result (<= (car result) point))
	(setq str (buffer-substring-no-properties (car result) (cdr result)))))
    str))

(defun hiki-edit-next-anchor (&optional prev)
  "次のアンカーへ移動する。

PREV が non-nil ならば、前のアンカーへ移動する。"
  (interactive "P")
  (goto-char (or (car (hiki-search-anchor (point) prev))
		 (point))))

(defun hiki-search-anchor (point &optional prev)
  "POINT から最も近いアンカーを探す。

見つかったら (beginning . end) を、見つからなかったら nil を 返す"
  (let ((case-fold-search nil)
	(alist hiki-anchor-regexp-alist)
	result)
    (save-excursion
      (while alist
	(goto-char point)
	(if (if prev (re-search-backward (car (car alist)) nil t nil)
	      (re-search-forward (car (car alist)) nil t nil))
	    (when (or (null result) 
		      (> (car result) (match-beginning (cdr (car alist)))))
	      (setq result
		    (cons (match-beginning (cdr (car alist)))
			  (match-end (cdr (car alist)))))))
	(setq alist (cdr alist))))
    result))

(defun hiki-edit-rename-buffer (sitename pagename pagetitle frozenp)
  (let ((name
	 (format "[%s%s] %s%s"
		 sitename (if (string= pagename pagetitle) "" (concat ":" pagename))
		 pagetitle (if frozenp " (frozen)" ""))))
    (or (string= name (buffer-name))
	(rename-buffer name t))))

(defun hiki-edit-url (str &optional url-encoded)
  "URL を指定して編集する。"
  (interactive "sURL: ")
  (let (url pagename site-info)
    (or	(string-match "^\\(http://[^?]+\\)\\?\\(.+\\)$" str)
	(error "Illegal URL. (%s)" str))
    (setq url (match-string 1 str))
    (setq pagename (match-string 2 str))
    (when (string-match "=" pagename)
      (if (string-match "\\(^\\|[?&;]\\)p=\\(.+\\)" pagename)
	  (setq pagename (match-string 2 pagename))
	(error "Illegal URL. (%s)" str)))
    (setq site-info (list url url))
    (hiki-edit-page 
     (hiki-http-url-unhexify-string pagename hiki-coding-system) site-info)))

(defun hiki-edit-quit ()
  (interactive)
  (let ((site-info hiki-site-info)
	(pagename hiki-pagename)
	win cancelled)
    (setq buffer-read-only t)
    (when (buffer-modified-p)
      (if (y-or-n-p "Buffer is modified. Really quit?")
	  (progn
	    (kill-buffer (current-buffer))
	    (setq hiki-page-buffer-alist
		  (remassoc 
		   (list (hiki-site-name site-info) pagename) 
		   hiki-page-buffer-alist))
	    (delete-other-windows))
	(setq cancelled t)))
    (when (not cancelled)
      (cond
       ((setq win (get-buffer-window (hiki-index-buffer-name site-info)))
	(select-window win))
       (t (delete-other-windows)))
      (hiki-index site-info t pagename))))

(defun hiki-edit-reload ()
  "現在編集中のページをリロードする。"
  (interactive)
  (let ((selected-pagename hiki-pagename))
    (hiki-edit)))

(defun hiki-edit (&optional select-site)
  "ページ名を指定して編集する。

SELECT-SITE が non-nil の時は、SITE名も指定する。"
  (interactive "P")
  (hiki-initialize)
  (let ((point (point))
	(start (window-start))
	site-info pagename (same-site t) same-page)
    ;; site-name input (if required)
    (cond
     ((and (hiki-site-name) (not select-site))
      (setq site-info hiki-site-info))
     (t
      (setq site-info (hiki-read-site-name))
      (when (not (string= (hiki-site-name site-info) (hiki-site-name)))
	(setq same-site nil))))
    ;; pagename input
    (setq pagename 
	  (if (boundp 'selected-pagename)
	      selected-pagename
	    (hiki-read-pagename 
	     (or (hiki-current-anchor-string) hiki-pagename "FrontPage")
	     (hiki-site-name site-info))))
    (if (string= pagename hiki-pagename) (setq same-page t))
    ;; edit
    (hiki-edit-page pagename site-info)
    ;; restore point (if required)
    (when (and same-site same-page)
      (set-window-start (selected-window) start)
      (goto-char point))))

;;; 一覧モード(hiki-index-*)

(define-derived-mode hiki-index-mode text-mode "Hiki Index"
  "Major mode for Hiki index.

\\{hiki-index-mode-map}"
  (make-local-variable 'hiki-site-info)
  (make-local-variable 'hiki-index-page-info-list)
  (make-local-variable 'hiki-index-sort-key)
  (hiki-index-setup-keys)
  (run-hooks 'hiki-index-mode-hook))

(defun hiki-index-setup-keys ()
  "Set up keymap for hiki-index-mode.
If you want to set up your own key bindings, use `hiki-index-mode-hook'."
  (define-key hiki-index-mode-map "\r" 'hiki-index-edit-page-current-line)
  (define-key hiki-index-mode-map "e" 'hiki-index-edit-page)
  (define-key hiki-index-mode-map "." 'hiki-index-display-page)
  (define-key hiki-index-mode-map " " 'hiki-index-display-page-next)
  (define-key hiki-index-mode-map "S" 'hiki-index-sort)
  (define-key hiki-index-mode-map "R" 'hiki-index-refetch-index)
  (define-key hiki-index-mode-map "q" 'hiki-index-suspend)
  (define-key hiki-index-mode-map "Q" 'hiki-index-quit)
  (define-key hiki-index-mode-map "I" 'hiki-index-login)
  (define-key hiki-index-mode-map "O" 'hiki-index-logout)
  )

(defun hiki-index (&optional site-info refetch pagename)
  "一覧モードに入る。

SITE-INFO が指定されていなければ、ミニバッファから読み込む。
REFETCH が nil ですでにバッファが存在するなら、HTTP GET しない。"
  (interactive "P")
  (hiki-initialize)
  (let (buf)
    ;; site-name input (if required)
    (when (null site-info)
      (setq site-info (hiki-read-site-name)))
    (setq buf (hiki-display-index site-info refetch pagename))
    (switch-to-buffer buf)
    (unless pagename (delete-other-windows))))

(defun hiki-display-index (site-info &optional refetch pagename)
  "一覧を表示し、バッファを返す。

REFETCH が nil で既にバッファが存在するなら、HTTP GET しない。
PAGENAME に対応した行があれば、カーソルをそこに移動する。 "
  (let ((old-buf (current-buffer))
	(buf (hiki-index-get-buffer-create site-info)))
    (switch-to-buffer buf)
    (setq buffer-read-only nil)
    (erase-buffer)
    (when (or refetch (null hiki-index-page-info-list))
      (message "Loading...")
      (setq hiki-index-page-info-list (hiki-fetch-index site-info))
      (message "Loading... done."))
    (mapcar (lambda (page-info)
	      (insert (hiki-index-page-info-string page-info site-info)))
	    hiki-index-page-info-list)
    (set-buffer-modified-p nil)
    (hiki-index-sort-by)
    (setq buffer-read-only t)
    (goto-char (point-min))
    (when pagename
      (dolist (elm hiki-index-page-info-list)
	(when (string= (nth 1 elm) pagename)
	  (re-search-forward (format "^%4d" (nth 0 elm)))
	  (beginning-of-line)
	  (recenter))))
    (switch-to-buffer old-buf)
    buf))

(defun hiki-index-get-buffer-create (site-info)
  "一覧表示用のバッファを返す。"
  (let ((buf-name (hiki-index-buffer-name site-info)))
    (or (get-buffer buf-name)
	(progn
	  (save-excursion
	    (get-buffer-create buf-name)
	    (set-buffer buf-name)
	    (hiki-index-mode)
	    (setq hiki-site-info site-info)
	    (get-buffer buf-name))))))

(defun hiki-index-page-info-string (page-info site-info)
  (let ((num (nth 0 page-info))
	(name (nth 1 page-info))
	(title (nth 2 page-info))
	(extra (nth 3 page-info))) 
    (format "%4d %s %s %s\n" num
	    (if (hiki-page-buffer-name name site-info) "V" " ")
	    (hiki-prefix
	     (concat title
		     (if (string= title name)
			 ""
		       (format " <%s>" name))) 35)
	    extra)))

(defun hiki-index-display-page (&optional refetch)
  "現在行のページを表示する。

REFETCH が nil ですでにバッファが存在するなら、HTTP GET しない。"
  (interactive)
  (let ((point (point))
	(page-info (hiki-index-page-info-current-line))
	pagename)
    (when page-info
      (setq pagename (nth 1 page-info))
      (delete-other-windows)
      (split-window nil 10)
      (recenter t)
      (other-window 1)
      (hiki-display-page pagename hiki-site-info refetch)
      (setq buffer-read-only t)
      (other-window 1))
    (hiki-index hiki-site-info nil pagename)
    (goto-char point)))

(defun hiki-index-display-page-next (&optional refetch)
  "現在行のページを表示する。すでに表示されている時はスクロールする。

REFETCH が nil ですでにバッファが存在するなら、HTTP GET しない。"
  (interactive)
  (let ((page-info (hiki-index-page-info-current-line))
	(old-win (selected-window))
	pagename buf win)
    (when page-info
      (setq pagename (nth 1 page-info))
      (setq buf (cdr (assoc (list (hiki-site-name hiki-site-info) pagename) 
			    hiki-page-buffer-alist)))
      (if (or (null buf) (null (setq win (get-buffer-window buf))))
	  (hiki-index-display-page refetch)
	(let ((other-window-scroll-buffer buf)
	      (start (window-start win)))
	  (scroll-other-window)
;;; スクロール出来ない時は次行に移る。
;;;	  (when (= (window-start win) start)
;;;	    (forward-line)
;;;	    (hiki-index-display-page refetch))
	  )))))

(defun hiki-index-edit-page-current-line ()
  "現在行のページを編集する。"
  (interactive)
  (hiki-index-edit-page (nth 1 (hiki-index-page-info-current-line))))

(defun hiki-index-edit-page (&optional pagename)
  "ページを編集する。"
  (interactive)
  (let ((index-buf (current-buffer))
	edit-buf start)
    (unless pagename
      (setq pagename
	    (hiki-read-pagename (nth 1 (hiki-index-page-info-current-line)) 
				 (hiki-site-name))))
    (when (and pagename 
	       (setq edit-buf (hiki-edit-page pagename hiki-site-info)))
      (switch-to-buffer index-buf)
      (delete-other-windows)
      (split-window nil 10)
      (setq start (window-start))
      (recenter)
      (hiki-display-index hiki-site-info nil pagename)
      (set-window-start (selected-window) start)
      (other-window 1)
      (switch-to-buffer edit-buf))))

(defun hiki-index-page-info-current-line ()
  "現在行のページ情報(list)を返す。"
  (let (num)
    (save-excursion
      (beginning-of-line)
      (re-search-forward "\\([0-9]+\\)" nil t nil)
      (setq num (match-string 1)))
    (cond
     (num (nth (1- (string-to-number num)) hiki-index-page-info-list))
     (t nil))))

(defun hiki-index-page-info (pagename)
  "PAGENAME の page-info を返す。知らなければ nil。"
  (let (result)
    (dolist (page-info hiki-index-page-info-list)
      (when (string= (nth 1 page-info) pagename)
	(setq result page-info)))
    result))

(defun hiki-index-refetch-index ()
  "一覧の再読み込みを行う。"
  (interactive)
  (hiki-index hiki-site-info t (nth 1 (hiki-index-page-info-current-line))))

(defun hiki-index-sort (&optional rev)
  "一覧のソートを行う"
  (interactive "P")
  (message "Sorting...")
  (hiki-index-sort-by 
   (hiki-read-char-with-retry "Sort by n)umber or d)ate? " nil '(?n ?d))
   rev)
  (message "Sorting... done."))

(defun hiki-index-suspend ()
  "hiki-index を一時中断する。"
  (interactive)
  (delete-other-windows)
  (dolist (elm hiki-page-buffer-alist)
    (bury-buffer (cdr elm)))
  (replace-buffer-in-windows (current-buffer)))

(defun hiki-index-quit ()
  "hiki-index を終了する。"
  (interactive)
  (let ((tmp hiki-page-buffer-alist))
    (delete-other-windows)
    (dolist (elm hiki-page-buffer-alist)
      (when (string= (nth 0 (car elm)) (hiki-site-name))
	(kill-buffer (cdr elm))
	(setq tmp (remassoc (car elm) tmp))))
    (setq hiki-page-buffer-alist tmp)
    (kill-buffer (current-buffer))))

(defun hiki-index-login ()
  (interactive)
  (let (username password post-data buf)
    (sit-for 0.1)
    (setq username (read-from-minibuffer (format "Username for %s: " (car hiki-site-info))))
    (setq password (read-passwd (format "Password for %s: " (car hiki-site-info))))
    (add-to-list 'post-data (cons "c" "login"))
    (add-to-list 'post-data (cons "name" username))
    (add-to-list 'post-data (cons "password" password))
    (setq buf (hiki-http-request 'post nil nil (hiki-site-url) post-data))
    (set-buffer buf)
    (goto-char (point-min))
    (if (re-search-forward "HTTP/1.[01] \\([0-9][0-9][0-9]\\) \\(.*\\)" nil t)
	(let ((code (match-string 1))
	      (desc (match-string 2)))
	  (cond ((equal code "302")
		 (message "Logged in."))
		(t
		 (message "Username and/or Password is wrong!!.")))))))

(defun hiki-index-logout ()
  (interactive)
  (let (post-data buf)
    (add-to-list 'post-data (cons "c" "logout"))
    (setq buf (hiki-http-request 'post nil nil (hiki-site-url) post-data))
    (message "Logged out.")))

;;; func

(defun hiki-display-page (pagename site-info &optional refetch)
  "ページのを表示する

REFETCH が nil ですでにバッファが存在するなら、HTTP GET しない。"
  (let ((not-cancelled t)
	result body keyword pagetitle password history point buf new-page)
    (setq buf (cdr (assoc (list (hiki-site-name site-info) pagename) 
		     hiki-page-buffer-alist)))
    (if (and buf (buffer-name buf) (not refetch))
	(progn 
	  (switch-to-buffer buf)
	  (goto-char (point-min)))
      (and buf (kill-buffer buf))
      (message "Loading...")
      (setq result (hiki-fetch-source pagename (hiki-site-url site-info)))
      (setq body (cdr (assoc 'body result)))
      (setq pagetitle (cdr (assoc 'pagetitle result)))
      (setq password (cdr (assq 'password result)))
      (setq keyword (cdr (assoc 'keyword result)))
      (when 
	  (and body 
	       (or (> (length body) 0)
		   (progn
		     (setq not-cancelled (y-or-n-p (format "Page %s is not exist. Create new page?" pagename)))
		     (if not-cancelled
			 (setq new-page t)
		       (setq result nil))
		     not-cancelled)))
	(setq buf (generate-new-buffer "*hiki tmp*"))
	(switch-to-buffer buf)
	(hiki-edit-rename-buffer (hiki-site-name site-info) pagename pagetitle password)
	(save-excursion
	  (when keyword
	    (insert (hiki-propertize "Keywords:" 'read-only t 'front-sticky t 'rear-nonsticky t 'hiki-special t))
	    (insert (hiki-propertize "\n" 'hiki-special t))
	    (insert (hiki-propertize (format "%s\n" keyword) 'hiki-special t))
	    (insert (hiki-propertize "----\n" 'read-only t 'front-sticky t 'rear-nonsticky t 'hiki-special t)))
	  (setq point (point))
	  (insert body)
	  (goto-char (point-min))
	  (hiki-replace-entity-refs)
	  (hiki-edit-mode)
	  (setq hiki-edit-new-page new-page)
	  (set-buffer-modified-p nil)
	  (add-to-list 'hiki-page-buffer-alist
		       (cons (list (hiki-site-name site-info) pagename) (current-buffer)))
	  (message "Loading... done."))
	(goto-char point))
      result)))

(defun hiki-edit-page (pagename site-info)
  "PAGENAME の編集モードに入る。バッファを返す。"
  (let ((result (hiki-display-page pagename site-info t)))
    (when result
      (setq hiki-md5hex (cdr (assq 'md5hex result)))
      (setq hiki-session-id (cdr (assq 'session-id result)))
      (setq hiki-update-timestamp (cdr (assq 'update-timestamp result)))
      (setq hiki-pagename pagename)
      (setq hiki-pagetitle (or (cdr (assq 'pagetitle result)) pagename))
      (setq hiki-site-info site-info)
      (or (setq history (assoc (hiki-site-name) hiki-pagename-history))
	  (setq hiki-pagename-history (cons (setq history (cons (hiki-site-name) nil)) hiki-pagename-history)))
      (or (member hiki-pagename (cdr history))
	  (setcdr history (cons (cons hiki-pagename nil) (cdr history))))
      (set-buffer-modified-p nil)
      (current-buffer))))

(defun hiki-fetch-index (site-info)
  "ページ一覧を取得する。"
  (let (indexes history (i 1)
                (buf (hiki-http-request 'get "index" nil (hiki-site-url site-info))))
    (when (bufferp buf)
      (save-excursion
        (set-buffer buf)
        (re-search-forward "<ul>\n\\s-*" nil t nil)
        (while (and (equal (char-after) ?<)
                    (re-search-forward "<a href=\"\\([^\"]*\\)\">\\([^<]*\\)</a>: \\([^<]*\\)</li>" nil t nil))
          (let ((page-url (match-string 1))
                (page-title (match-string 2))
                (page-description (match-string 3)))
            (setq indexes 
                  (cons
                   (list i (hiki-http-url-unhexify-string (if (string-match "\\?\\(.*\\)" page-url)
                                                              (match-string 1 page-url)
                                                            "FrontPage")
                                                          hiki-coding-system)
                         (hiki-replace-entity-refs page-title)
                         (hiki-replace-entity-refs page-description)) indexes)))
          (setq i (1+ i))))
      (or (setq history (assoc (hiki-site-name site-info) hiki-pagename-history))
          (setq hiki-pagename-history (cons (setq history (cons (hiki-site-name site-info) nil)) hiki-pagename-history)))
      (setcdr history (mapcar (lambda (elm) (cons (nth 1 elm) nil)) indexes))
      (reverse indexes))))

(defun hiki-fetch-source (pagename site-url)
  "Hiki の ソースを取得する。

'((md5hex . \"...\")
  (session-id . \"...\")
  (body . \"...\")
  (pagetitle . (...)) 
  (keyword . (...)) 
  (update-timestamp . t/nil)
  (password . t/nil)) を返す。"
  (let (buf start end pt result)
    (setq buf (hiki-http-request 'get "edit" pagename site-url))
    (when (bufferp buf)
      (save-excursion
	(set-buffer buf)
	;; md5hex
	(re-search-forward "<input [^>]+name=\"md5hex\" value=\"\\([^>\"]*\\)\">" nil t nil)
	(setq result (cons (cons 'md5hex (match-string 1)) result))
	;; session id
	(re-search-forward "<input [^>]+name=\"session_id\" value=\"\\([^>\"]*\\)\">" nil t nil)
	(setq result (cons (cons 'session-id (match-string 1)) result))
	(setq pt (point))
	;; textarea
	(re-search-forward "<textarea [^>]+name=\"contents\"[^>]*>" nil t nil)
	(setq start (match-end 0))
	(re-search-forward "</textarea>" nil t nil)
	(setq end (match-beginning 0))
	(setq result (cons (cons 'body (buffer-substring start end)) result))
	;; page_title
	(goto-char pt)
	(re-search-forward "<input [^>]+name=\"page_title\" [^>]+value=\"\\([^>\"]*\\)\">" nil t nil)
	(setq result (cons (cons 'pagetitle (hiki-replace-entity-refs (match-string 1))) result))
	;; update timestamp?
	(if (re-search-forward "<input type=\"checkbox\" name=\"update_timestamp\" value=\"on\" checked>" nil t nil)
	    (setq result (cons (cons 'update-timestamp t) result))
	  (setq result (cons (cons 'update-timestamp nil) result)))
	;; keyword
	(when (re-search-forward "<textarea [^>]+name=\"keyword\" [^>]+>" nil t nil)
	  (setq start (match-end 0))
	  (re-search-forward "</textarea>" nil t nil)
	  (setq end (match-beginning 0))
	  (setq result (cons (cons 'keyword (hiki-replace-entity-refs (buffer-substring start end))) result)))
	;; frozen?
	(if (re-search-forward "<input type=\"checkbox\" name=\"freeze\" value=\"on\" checked>" nil t nil)
	    (setq hiki-freeze t)
	  (setq hiki-freeze nil))))
    result))

(defun hiki-edit-save-page (&optional toggle)
  (interactive "P")
  (let (buf contents post-data pagetitle password freeze keywords result)
    (message "Sending... ")
    (sit-for 0.1)
    (setq pagetitle (read-from-minibuffer
		     (format "Page title for [%s] %s: " (car hiki-site-info) hiki-pagename)
		     (or hiki-pagetitle hiki-pagename) nil nil nil (or hiki-pagetitle hiki-pagename)))
    (goto-char (point-min))
    (when (get-text-property (point) 'hiki-special)
      (re-search-forward "^Keywords:$" nil t nil)
      (let (start end)
        (setq start (+ (match-end 0) 1))
        (re-search-forward "^----$" nil t nil)
        (setq end (match-beginning 0))
        (setq keywords (buffer-substring-no-properties start end)))
      (goto-char (next-single-property-change (point) 'hiki-special)))
    (setq contents (buffer-substring-no-properties (point) (point-max)))
    (add-to-list 'post-data (cons "c" "save"))
    (add-to-list 'post-data (cons "p" hiki-pagename))
    (add-to-list 'post-data (cons "page_title" pagetitle))
    (add-to-list 'post-data (cons "keyword" (or keywords "")))
    (add-to-list 'post-data (cons "md5hex" hiki-md5hex))
    (add-to-list 'post-data (cons "session_id" hiki-session-id))
    (if (not (null hiki-update-timestamp))
	(add-to-list 'post-data (cons "update_timestamp" "on")))
    (if (not (null hiki-freeze))
	(add-to-list 'post-data (cons "freeze" "on")))
    (add-to-list 'post-data (cons "contents" contents))
    (add-to-list 'post-data (cons "save" "save"))
    (setq buf 
	  (hiki-http-request 'post nil hiki-pagename
			     (hiki-site-url) post-data))
    (when (bufferp buf)
      (save-excursion
	(set-buffer buf)
	(setq result
	      (cond 
	       ((progn (goto-char (point-min)) 
		       (re-search-forward "<pre>" nil t nil)) 'conflict)
	       ((progn (goto-char (point-min)) 
		       (re-search-forward "<textarea [^>]+>" nil t nil)) 'wrong-pass)
	       (t 'success))))
      (cond
       ((equal result 'conflict)
	(hiki-conflict-show-diff)
	(error "Conflict! (--- server, +++ yours)"))
       ((equal result 'wrong-pass)
	(error "Password is wrong!")))
      (message "Sending... done.")
      (set-buffer-modified-p nil)
      (setq buffer-read-only t)
      (hiki-password-store (car hiki-site-info) hiki-pagename (if freeze password nil))
      (hiki-edit-rename-buffer (car hiki-site-info) hiki-pagename (setq hiki-pagetitle pagetitle) freeze)
      (and (functionp hiki-browser-function)
	   (funcall hiki-browser-function
		    (format "%s?%s" (hiki-site-url) (hiki-http-url-hexify-string hiki-pagename hiki-coding-system))))
      (hiki-edit-quit))))

(defun hiki-conflict-show-diff ()
  "現在のバッファとサーバのデータを比較し、表示する。"
  (let 
      ((file1 (expand-file-name (make-temp-name "hiki") 
				temporary-file-directory))
       (file2 (expand-file-name (make-temp-name "hiki")
				temporary-file-directory))
       (str (buffer-substring (point-min) (point-max)))
       (pagename hiki-pagename)
       (site-url (hiki-site-url))
       diff-process diff-switches lines)
    (with-temp-file file1 
      (insert (cdr (assoc 'body (hiki-fetch-source pagename site-url))))
      (if (> (current-column) 0) (insert "\n"))
      (setq lines (count-lines (point-min) (point-max))))
    (with-temp-file file2 
      (insert str)
      (if (> (current-column) 0) (insert "\n")))
    (if (get-buffer hiki-diff-buffer-name) 
	(kill-buffer hiki-diff-buffer-name))
    (setq diff-process
	  (start-process "diff" hiki-diff-buffer-name
			 diff-command "-U" (format "%d" lines) file1 file2))
    (set-process-sentinel diff-process (lambda (process event)))
    (save-excursion
      (set-buffer hiki-diff-buffer-name)
      (while 
	  (progn 
	    (accept-process-output diff-process 1)
	    (not (equal (process-status (current-buffer)) 'exit))))
      ;; delete header
      (goto-char (point-min))
      (forward-line 3)
      (delete-region (point-min) (point))
      (pop-to-buffer (process-buffer diff-process))
      (setq buffer-read-only t))
    (delete-file file1)
    (delete-file file2)))

;;; Util

(defun hiki-site-name (&optional site-info)
  (nth 0 (or site-info hiki-site-info)))

(defun hiki-site-url (&optional site-info)
  (nth 1 (or site-info hiki-site-info)))

(defun hiki-site-style (&optional site-info)
  (or (nth 2 (or site-info hiki-site-info))
      'default))

(defun hiki-page-buffer-name (pagename site-info)
  (let ((buf (cdr (assoc (list (hiki-site-name site-info) pagename) 
			 hiki-page-buffer-alist))))
    (and buf (buffer-name buf))))

(defun hiki-index-buffer-name (&optional site-info)
  (format "Hiki index <%s>" (hiki-site-name site-info)))

(defun hiki-index-sort-by (&optional key arg)
  (unless key
    (unless hiki-index-sort-key 
      (setq hiki-index-sort-key '(?n nil)))
    (setq key (nth 0 hiki-index-sort-key))
    (setq arg (nth 1 hiki-index-sort-key)))
  (setq hiki-index-sort-key (list key arg))
  (setq buffer-read-only nil)
  (save-excursion
    (goto-char (point-min))
    (cond
     ((eq key ?n) (hiki-index-sort-subr arg 0))
     ((eq key ?d) (hiki-index-sort-subr (not arg) 3))))
  (set-buffer-modified-p nil)
  (setq buffer-read-only t))

(defun hiki-index-sort-subr (rev num)
  (sort-subr rev
	     'forward-line 'end-of-line
	     (lambda () (nth num (hiki-index-page-info-current-line)))))

(defun hiki-replace-entity-refs (&optional str)
  "Replace entity references.

If STR is a string, replace entity references within the string.
Otherwise replace all entity references within current buffer."
  (hiki-do-replace-entity-ref "&amp;" "&"	 
   (hiki-do-replace-entity-ref "&lt;" "<"
    (hiki-do-replace-entity-ref "&gt;" ">"
     (hiki-do-replace-entity-ref "&quot;" "\""
      (hiki-do-replace-entity-ref "&#39;" "'" str))))))

(defun hiki-do-replace-entity-ref (from to &optional str)
  (save-match-data
    (save-excursion
      (goto-char (point-min))
      (if (stringp str)
	  (progn
	    (while (string-match from str)
	      (setq str (replace-match to nil nil str)))
	    str)
	(while (search-forward from nil t)
	  (replace-match to nil nil))))))
  
(defun hiki-propertize (string &rest properties)
  "Return a copy of STRING with text PROPERTIES added."
  (prog1
      (setq string (copy-sequence string))
    (add-text-properties 0 (length string) properties string)))

(defun hiki-prefix (str width)
  "STR の先頭を WIDTH文字を取り出す。

WIDTH に満たない場合は、末尾に空白がパディングされる。"
  (let (l (result "")
	(w (string-width str)))
    (if (< w width)
	(setq str (concat str (make-string (1- width) ? ))
	      w (string-width str)))
    (setq l (string-to-list str))
    (while (< (char-width (car l)) width)
      (setq result (concat result (char-to-string (car l))))
      (setq width (- width (char-width (car l))))
      (setq l (cdr l)))
    (concat result (make-string width ? ))))

;;; Util (http-*)

(defun hiki-http-url-unhexify-string (str coding)
  "Unescape characters in a string."
  (save-match-data
    (let ((result (string-as-unibyte str)) (pos -1))
      (while (setq pos (string-match "+" result (1+ pos)))
	(setq result (replace-match " " nil nil result)))
      (setq pos -1)
      (while (setq pos (string-match 
			"%\\([0-9a-fA-F][0-9a-fA-F]\\)" result (1+ pos)))
	(setq result 
	      (replace-match 
	       (format "%c" (eval (read (concat "?\\x" 
						(match-string 1 result)))))
	       t t result)))
      (decode-coding-string result coding))))

(defun hiki-http-url-hexify-alist (alist coding)
  (mapcar 
   (lambda (c) 
     (cons (car c) (and (cdr c) (hiki-http-url-hexify-string (cdr c) coding))))
   alist))

;; derived from url.el
(defconst hiki-http-url-unreserved-chars
  '(
    ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z
    ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M ?N ?O ?P ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z
    ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9
    ?$ ?- ?_ ?. ?! ?~ ?* ?' ?\( ?\) ?,)
  "A list of characters that are _NOT_ reserve in the URL spec.
This is taken from draft-fielding-url-syntax-02.txt - check your local
internet drafts directory for a copy.")

;; derived from url.el
(defun hiki-http-url-hexify-string (str coding)
  "Escape characters in a string.
At first, encode STR using CODING, then url-hexify."
  (mapconcat
   (function
    (lambda (char)
      (if (not (memq char hiki-http-url-unreserved-chars))
          (if (< char 16)
              (upcase (format "%%0%x" char))
            (upcase (format "%%%x" char)))
        (char-to-string char))))
   (encode-coding-string str coding) ""))

(defun hiki-http-fetch (url method &optional user pass data)
  "Fetch via HTTP.

URL is a url to be POSTed.
METHOD is 'get or 'post.
USER and PASS must be a valid username and password, if required.  
DATA is an alist, each element is in the form of (FIELD . DATA).

If no error, return a buffer which contains output from the web server.
If error, return a cons cell (ERRCODE . DESCRIPTION)."
  (let (connection server port path buf str len)
    (string-match "^http://\\([^/:]+\\)\\(:\\([0-9]+\\)\\)?\\(/.*$\\)" url)
    (setq server (match-string 1 url)
          port (string-to-int (or (match-string 3 url) "80"))
          path (if hiki-http-proxy-server url (match-string 4 url)))
    (setq str (mapconcat
               '(lambda (x)
                  (concat (car x) "=" (cdr x)))
               data "&"))
    (setq len (length str))
    (save-excursion
      (setq buf (get-buffer-create (concat "*result from " server "*")))
      (set-buffer buf)
      (erase-buffer)
      (setq connection
            (as-binary-process
             (open-network-stream (concat "*request to " server "*")
                                  buf
                                  (or hiki-http-proxy-server server)
                                  (or hiki-http-proxy-port port))))
      (process-send-string
       connection
       (concat (if (eq method 'post)
                   (concat "POST " path)
                 (concat "GET " path (if (> len 0)
                                         (concat "?" str))))
               " HTTP/1.0\r\n"
               (concat "Host: " server "\r\n")
	       (if (not (null hiki-http-cookie))
		   (concat "Cookie: session_id=" (cdr (assoc 'session-id hiki-http-cookie))
			   "\r\n"))
               "Connection: close\r\n"
               "Content-type: application/x-www-form-urlencoded\r\n"
               (if (and user pass)
                   (concat "Authorization: Basic "
                           (base64-encode-string
                            (concat user ":" pass))
                           "\r\n"))
               (if (eq method 'post)
		   (concat "Content-length: " (int-to-string len) "\r\n"
			   "\r\n"
			   str))
               "\r\n"))
      (goto-char (point-min))
      (while (not (search-forward "</body>" nil t))
        (unless (accept-process-output connection hiki-http-timeout)
          (error "HTTP fetch: Connection timeout!"))
        (goto-char (point-min)))
      (goto-char (point-min))
      (save-excursion
        (if (re-search-forward "HTTP/1.[01] \\([0-9][0-9][0-9]\\) \\(.*\\)" nil t)
            (let ((code (match-string 1))
                  (desc (match-string 2)))
	      (if (re-search-forward "Set-Cookie: session_id=\\([^;]+\\);.*" nil t)
		  (let ((session-id (match-string 1)))
		    (setq hiki-http-cookie (list
					    (cons 'session-id session-id)))))
	      (cond ((equal code "200")
                     buf)
		    ((equal code "302")
		     buf)
		    ((equal code "404")
		     (cons code (hiki-get-error-message buf)))
		    (t
                     (cons code desc)))))))))

(defun hiki-http-cookie-expired ()
  (setq hiki-http-cookie nil))

(defun hiki-get-error-message (buf)
  (set-buffer buf)
  (re-search-forward "<h1 class=\"header\">Error</h1>" nil t nil)
  (goto-char (match-end 0))
  (re-search-forward "<div>\\([^<]+\\)</div>" nil t nil)
  (match-string 1))

(provide 'hiki-mode)
;;; hiki-mode.el ends here
