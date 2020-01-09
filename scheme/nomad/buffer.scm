;; buffer.scm
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

(define-module (nomad buffer)
  #:use-module (emacsy emacsy)
  #:use-module (g-golf)
  #:use-module (ice-9 format)
  #:use-module (ice-9 pretty-print)
  #:use-module (nomad eval)
  #:use-module (nomad frame)
  #:use-module (nomad minibuffer)
  #:use-module (nomad repl)
  #:use-module (nomad text)
  #:use-module (nomad views)
  #:use-module (nomad gtk generics)
  #:use-module (nomad widget)
  #:use-module (oop goops)
  #:use-module (srfi srfi-1)
  #:export (current-url
            make-buffer-socket
            <nomad-webview-buffer>
            buffers-contain?
            buffers->uri))

(gi-import "Nomad")

(define-class <nomad-webview-buffer> (<buffer>)
  (init-uri #:init-keyword #:init-uri #:init-value "https://gnu.org"))

(define-interactive (current-url)
  "Returns the current url"
  (message "~a"
           (buffer-uri (current-buffer))))

(define (make-buffer-socket url socket)
  "Write `make-buffer' comand with arg URL to a SOCKET."
  (write-socket (format #f "~S" `(make-buffer ,url))
                   socket))

(define-interactive (kill-some-buffers)
  "Kill all buffers but the message buffer"
  (for-each (lambda (buffer)
              (switch-to-buffer buffer)
              (kill-buffer))
            (buffer-list)))

(define (buffers-contain? uri)
  "Returns #t of buffer-list contains URI"
  (let ((contains #f))
    (for-each (lambda (buffer)
                (when (string= uri
                               (buffer-name buffer))
                  (set! contains #t)))
              (buffer-list))
    contains))

(define (buffers->uri)
  "Returns a list of uri's for all buffers"
  (filter-map (lambda (buffer)
                (if (eq? (class-of buffer) <webview-buffer>)
                    (buffer-name buffer)
                    #f))
              (buffer-list)))

(define-interactive (show-buffers)
  "Displays buffers in minipopup"
  (begin (render-popup completion-view
                       (buffers->uri)
                       -1)
         (length (buffers->uri))))

(define-interactive (message-buffers)
  "Pretty prints the buffers to echo area"
  (message "~a" (with-output-to-string (lambda _ (pretty-print (buffer-list))))))

(define-interactive (make-content-buffer #:optional (name (read-from-minibuffer "Name: "))
                                         (content (read-from-minibuffer "Content: ")))
  "Creates a new webview buffer with NAME and CONTENT"
  (let ((buffer (make-webcontent-buffer name content)))
    (with-buffer buffer
                 (set-buffer-hooks!)
                 (buffer-render))
    (switch-to-buffer buffer)
    buffer))

(define-interactive (make-buffer #:optional (url (read-from-minibuffer "Url: ")))
  "Creates a new webview-buffer with URL"
  (let ((buffer (make-webview-buffer url)))
    (set-buffer-hooks! buffer)
    (buffer-load-uri buffer
                     (prefix-url url))
    (switch-to-buffer buffer)
    buffer))

(define-public (switch-if-not-current buffer)
  "Switch to buffer if it's not the current buffer already. Returns #t if buffer switched"
  (if (eq? buffer (current-buffer))
      #f
      (begin (switch-to-buffer buffer)
             #t)))

(define-public (redisplay-minibuffer)
  "Set the minibuffer graphical control to emacsy buffer state"
  (emacsy-tick)
  (when emacsy-display-minibuffer?
    (grab-readline))
  (set-source-text! (nomad-app-frame-get-readline (current-frame))
                    (emacsy-message-or-echo-area))
  (set-source-point! (current-echo-area)
                     (buffer:point minibuffer)))

(define-public (redisplay-buffers)
  "Converts text-buffers to <nomad-text-buffer> and inserts them into
notebook. Also updates buffer contents and buffer points"
  (for-each (lambda (buffer)
              (when (eq? <text-buffer> (class-of buffer))
                (text-buffer->nomad-text-buffer! buffer)
                (notebook-insert buffer 0))
              (when (eq? <nomad-text-buffer> (class-of buffer))
                (set-source-text! (get-source-widget (buffer-widget buffer))
                                  (buffer:buffer-string buffer))
                (set-source-point! (get-source-widget (buffer-widget buffer))
                                   (buffer:point buffer))))
            (buffer-list)))

(define-interactive (eval-buffer #:optional (buffer (current-buffer)))
  (catch #t
    (lambda _
      (message "~a"
               (eval-string (buffer:buffer-string buffer))))
    (lambda (key . vals)
      (message "Error: key: ~a value: ~a" key vals))))
