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

(define-module (nomad app)
  #:use-module (emacsy emacsy)
  #:use-module (nomad webview)
  #:use-module (emacsy buffer)
  #:use-module (nomad views)
  #:use-module (nomad buffer)
  #:use-module (nomad minibuffer)
  #:export (emacs-init-file
            app-init))

(define emacs-init-file "init.el")

(define (app-init)
  "This is called when the application is activated. Which ensures
controls are accessible to scheme"
  ;; Setup the scratch and messages
  ;;
  ;; FIXME: don't use localhost use instead sxml view to show scratch
  ;; and messages?
  (for-each (lambda buffer
              (with-buffer (car buffer)
                (define (on-enter)
                  (set-web-buffer! (local-var 'web-buffer)))
                (define (on-kill)
                  (format #t
                          "Destroying web-view ~a~%"
                          (local-var 'web-buffer))
                  (destroy-web-buffer! (local-var 'web-buffer)))
                (set! (local-var 'web-buffer)
                      (make-web-buffer "http://localhost"))
                (set! (local-var 'update)
                      #f)
                (add-hook! (buffer-enter-hook (car buffer))
                           on-enter)
                (add-hook! (buffer-kill-hook (car buffer))
                           on-kill)
                (on-enter)))
            (list messages scratch))
  ;; Setup the minibuffer
  (define-key minibuffer-local-map "C-n" 'next-line)
  (define-key minibuffer-local-map "C-p" 'previous-line)
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
    (agenda-schedule-interval (lambda _
                                (update-buffer-names))
                              10))
  ;; Create one buffer
  (make-buffer default-home-page))
