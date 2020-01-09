;; app.scm
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

(define-module (nomad application)
  #:use-module (emacsy buffer)
  #:use-module (emacsy emacsy)
  #:use-module (nomad buffer)
  #:use-module (nomad init)
  #:use-module (nomad lib)
  #:use-module (nomad options)
  #:use-module (nomad repl)
  #:use-module (nomad text)
  #:use-module (g-golf)
  #:use-module (nomad util)
  #:use-module (nomad views)
  #:use-module (nomad webview)
  #:export (<application>
            emacs-init-file
            shutdown-hook
            shutdown
            app-init))

(eval-when (expand load eval)
  (gi-import "Gio"))

(define-class <application> ())

(define-method (initialize (self <application>) args)
  (next-method)
  (init))

(define shutdown-hook (make-hook 0))

(define (shutdown)
  "Cleans up after guile and runs user shutdown hooks"
  (run-hook shutdown-hook))

(define-public (application-id)
  (let ((app (g-application-get-default)))
    (g-application-get-application-id app)))

(define (app-init)
  "This is called when the application is activated. Which ensures
controls are accessible to scheme"
  ;; (define-key minibuffer-local-map "C-n" 'next-line)
  ;; (define-key minibuffer-local-map "C-p" 'previous-line)
  ;; (define-key minibuffer-local-map "RET" 'minibuffer-execute)
  (with-buffer minibuffer
               (set! (local-var 'view)
                     completion-view)
               (set! (local-var 'selection)
                     0)
               (set! (local-var 'completions)
                     '())
               ;; (add-hook! (buffer-enter-hook (current-buffer))
               ;;            (lambda _
               ;;              (render-completion-popup-view)))
               ;; (add-hook! (buffer-exit-hook (current-buffer))
               ;;            hide-minibuffer-popup)
               (add-hook! shutdown-hook
                          (lambda _
                            (info "running shutdown hook..."))))

  (agenda-schedule-interval (lambda _
                              (redisplay-buffers))
                            50)
  ;; Create one buffer
  (make-buffer default-home-page)
  (run-hook startup-hook))