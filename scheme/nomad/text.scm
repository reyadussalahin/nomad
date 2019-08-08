;; text.scm
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

(define-module (nomad text)
  #:use-module (emacsy emacsy)
  #:use-module (g-golf)
  #:use-module (ice-9 optargs)
  #:use-module (nomad frame)
  #:use-module (nomad util)
  #:use-module (nomad lib)
  #:use-module (nomad pointer)
  #:use-module (oop goops)
  #:use-module (system foreign)
  )

(load-extension (dynamic-path) "init_guile_nomad_text")

(gi-import "GtkSource")

(define default-source-language "scheme")
(define default-source-theme "classic")

(define-class-public <nomad-text-buffer> (<widget-buffer>))

(define* (make-source-view #:optional theme language)
  (let ((view (make <gtk-source-view>))
        (t (or theme default-source-theme))
        (l (or language default-source-language)))
    (nomad-app-source-view-set-buffer view t
                                      l)
    view))

(define-public (text-buffer->pointer-buffer buffer)
  "Converts a <text-buffer> class to a pointer-buffer."
  (change-class buffer <nomad-text-buffer>)
  (info "converting ~a" buffer)
  (slot-set! buffer
             'widget
             (make-source-view))
  (add-hook! (buffer-enter-hook buffer)
             pointer-enter-hook)
  (add-hook! (buffer-kill-hook buffer)
             pointer-kill-hook)
  (notebook-insert buffer 0))