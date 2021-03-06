;; browser.scm
;; Copyright (C) 2017-2018 Michael Rosset <mike.rosset@gmail.com>

;; This file is part of Nomad

;; Nomad is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; Nomad is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;; See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (nomad webview)
  #:use-module (emacsy emacsy)
  #:use-module (ice-9 optargs)
  #:use-module (nomad buffer)
  #:use-module (nomad eval)
  #:use-module (nomad pointer)
  #:use-module (nomad util)
  #:use-module (nomad webkit)
  #:use-module (oop goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (system foreign)
  #:export (current-url
            scroll-down
            scroll-up
            hints
            webview-init
            default-home-page
            prefix-url
            search-provider-format
            webview-map
            firefox-webview-map
            webview-onload
            ;; ;; class constructors
            make-webview-buffer
            make-webcontent-buffer

            ;;methods
            set-buffer-hooks!
            buffer-back
            buffer-foward
            buffer-content
            buffer-render
            buffer-sync
            buffer-uri
            set-buffer-uri!
            ))

;;; <webview-buffer> extends <pointer-buffer> class
(define-class-public <webview-buffer>
  (<pointer-buffer>)
  (content #:accessor buffer-content #:init-keyword #:content))

(define-method (buffer-reload)
  (webkit-reload (buffer-pointer (current-buffer))))

(define-method (buffer-hints)
  (webkit-hints (buffer-pointer (current-buffer))))

(define-method (buffer-scroll-up)
  (webkit-scroll-up (buffer-pointer (current-buffer))))

(define-method (buffer-scroll-down)
  (webkit-scroll-down (buffer-pointer (current-buffer))))

(define-method (buffer-back)
  (webkit-back (buffer-pointer (current-buffer))))

(define-method (buffer-back (buffer <webview-buffer>))
  (webkit-back (buffer-pointer buffer)))

(define-method (buffer-forward)
  (webkit-forward (buffer-pointer (current-buffer))))

(define-method (buffer-forward (buffer <webview-buffer>))
  (webkit-forward (buffer-pointer buffer)))

(define-method (set-buffer-hooks!)
  (set-buffer-hooks! (current-buffer)))

(define-method (set-buffer-hooks! (buffer <webview-buffer>))
  (add-hook! (buffer-enter-hook buffer)
             pointer-enter-hook)
  (add-hook! (buffer-kill-hook buffer)
             pointer-kill-hook))

(define (webview-onload)
  "Update BUFFER on webview load"
  (set-buffer-name! (buffer-uri (current-buffer))))

(define-method (buffer-uri)
  (buffer-uri (current-buffer)))

(define-method (buffer-uri (buffer <webview-buffer>))
  (let ((pointer (buffer-pointer buffer)))
    ;; if the pointer is null fall back to the buffer name
    (if (null-pointer? pointer)
        (buffer-name buffer)
        (webkit-uri pointer))))

(define-method (set-buffer-uri! uri)
  (set-buffer-uri! uri (current-buffer)))

(define-method (set-buffer-uri! uri
                                (buffer <webview-buffer>))
  (webkit-load-uri (buffer-pointer (current-buffer))
                   uri))

(define-method (buffer-render)
  (buffer-render (current-buffer)))

(define-method (buffer-render (buffer <webview-buffer>))
  (webkit-load-html (buffer-pointer buffer) (buffer-content buffer)))

(define* (make-webview-buffer #:optional (uri default-home-page))
  "Constructs a new webview-buffer class"
  (let ((buffer (make <webview-buffer> #:name uri #:uri uri #:keymap webview-map)))
    (add-buffer! buffer)
    buffer))

(define* (make-webcontent-buffer name
                                 #:optional (content (format #f "<h2>~a</h2>" name)))
  "Constructs a new webcontent-buffer class"
  (let ((buffer (make <webview-buffer>
                  #:name name #:content content
                  #:keymap webview-map)))
    (add-buffer! buffer)
    buffer))

(define search-provider-format "https://duckduckgo.com/?q=~a")

(define default-home-page "https://www.gnu.org/software/guile")

;; FIXME: use a webview-buffer class instead of converting text-buffers
(define-public (buffer->webview-buffer buffer)
  "Modify <text-buffer> object BUFFER to <webview-buffer> class. Returns the new class type"
  (change-class buffer <webview-buffer>)
  (set-buffer-hooks! buffer)
  (set! (buffer-content buffer) (format #f "<h2>~a</h2>" (buffer-name buffer)))
  (class-of buffer))

(define (prefix-url url)
  "Returns a full protocol URI for domain URI.
e.g. (prefix-url \"gnu.org\") returns \"https://gnu.org\""
  (if (string-contains url "://") url
      (string-append "https://" url)))

(define-interactive (browse #:optional (url (read-from-minibuffer "URL: ")))
  "Browse to URI. URI is prefixed with https:// if no protocol is
specified. Returns the final URL passed to webkit"
  (set-buffer-uri! (prefix-url url) (current-buffer)))

(define-interactive (hints)
  (buffer-hints))

(define-interactive (scroll-up)
  "Scroll buffer up"
  (buffer-scroll-up))

(define-interactive (scroll-down)
  "Scroll buffer down"
  (buffer-scroll-down))

(define-interactive (forward)
  "Go forward in browser history"
  (buffer-forward))

(define-interactive (back)
  "Browse backwards in history"
  (buffer-back))

(define-interactive (home)
  "Load default home page"
  (set-buffer-uri! default-home-page))

(define-interactive (reload)
  "Reload current URI"
  (buffer-reload))

(define-interactive (make-query #:optional (q (read-from-minibuffer "Query: ")))
  "Makes a new buffer and queries ARG using 'search-provider-format"
  (make-buffer (simple-format #f search-provider-format q)))

(define-interactive (query #:optional (q (read-from-minibuffer "Query: ")))
  "Queries ARG using 'search-provider-format"
  (let ((uri (simple-format #f search-provider-format q)))
    (browse uri)))

(define-interactive (current-url)
  "Returns the current url"
  (message "~a"
           (buffer-uri (current-buffer))))

(define-interactive (copy-current-url)
  "Copy current url to clipboard"
  (yank-string (current-url))
  (message (webview-current-url)))

(define-interactive (tweak-url)
  "Edit the current-url."
  (browse (read-from-minibuffer "Url: " (current-url))))

(define current-search  #f)

(define-interactive
  (isearch-forward #:optional
                   (text (or current-search (read-from-minibuffer "I-search: "))))
  (set! current-search text)
  (webkit-find (buffer-pointer (current-buffer)) text)
  (message "I-search: ~a" text))

;; search providers
(define search-providers
  (circular-list "https://searx.info/?q=~a"
                 "https://google.com/?q=~a"
                 "https://duckduckgo.com/?q=~a"))

(define (pick-search-provider)
  (let ((s search-providers))
    (lambda ()
      (set! search-provider-format (car s))
      (set! s (cdr s)))))

(define-public cycle-search-provider (pick-search-provider))

(define-interactive (webview-keyboard-quit)
  (when current-search
    (set! current-search #f)
    (webkit-find-finish (buffer-pointer (current-buffer))))
  (keyboard-quit))

;; Provides firefox key mappings for webview-mode. This can be set as
;; the default webview mode map by using (!set webview-map
;; firefox-webview-map) in user-init-file
(define firefox-webview-map
  (list->keymap '(("C-g" webview-keyboard-quit)
                  ("C-f" isearch-forward)
                  ("C-u" next-buffer)
                  ("C-m" prev-buffer)
                  ("M-n" forward)
                  ("M-b" back)
                  ("M-h" home)
                  ("M-f" browse)
                  ("M-g" reload)
                  ("M-u" tweak-url)
                  ("M-c" copy-current-url)
                  ("C-s" query)
                  ("M-s" cycle-search-provider)
                  ("M-v" scroll-up)
                  ("C-v" scroll-down)
                  ("M-'" hints))))

;; Default webview key mappings
(define-public webview-map
  (list->keymap '(("C-u" back)
                  ("C-m" forward)
                  ("C-n" scroll-down)
                  ("C-p" scroll-up)
                  ("C-f" hints)
                  ("C-r" reload)
                  ("C-g" webview-keyboard-quit)
                  ("C-s" isearch-forward))))
