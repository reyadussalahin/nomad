;; widgets.scm
;; Copyright (C) 2017-2020 Michael Rosset <mike.rosset@gmail.com>

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

(define-module (nomad gtk widget)
  #:use-module (srfi srfi-26)
  #:use-module (emacsy emacsy)
  #:use-module (oop goops)
  #:use-module (g-golf)
  #:export (<widget-source-view>
            <widget-border>
            <widget-mini-popup>
            <widget-text-view>
            !grid
            set-source-text!
            set-source-point!
            container-child
            container-empty?))

(eval-when (expand load eval)
  (default-duplicate-binding-handler
    '(merge-generics replace warn-override-core warn last))

  (gi-import "Gdk")
  (for-each (lambda (x)
              (gi-import-by-name  (car x) (cdr x)))
            '(("Gtk" . "CssProvider")
              ("Gtk" . "StyleContext")
              ("Gtk" . "VBox")
              ("Gtk" . "DrawingArea")
              ("Gtk" . "ScrolledWindow")
              ("Gtk" . "Grid")
              ("Gtk" . "VSeparator")
              ("GtkSource" . "View")
              ("GtkSource" . "Buffer")
              ("GtkSource" . "Language")
              ("GtkSource" . "StyleScheme")
              ("GtkSource" . "StyleSchemeManager")
              ("GtkSource" . "LanguageManager")))
  (gi-import "Nomad"))



;; <widget-source-view> provides additional construction and initialization of
;; <gtk-source-view> specialized for nomads text views FIXME: this is
;; redundant due to <widget-text-view> but this is extra special due to
;; modeline and minibuffer switch this to use <nomad-text-view>
(define-class <widget-source-view> (<gtk-source-view>)
  (theme #:accessor !theme #:init-keyword #:theme #:init-value "classic")
  (buffer #:accessor !buffer
          #:init-keyword #:buffer
          #:init-value #f)
  (parent #:accessor !parent
          #:init-keyword #:parent
          #:init-value #f)
  (thunk  #:accessor !thunk
          #:init-keyword #:thunk
          #:init-value (lambda _ "no text thunk defined.")))

(define-method (initialize (self <widget-source-view>) args)
  (next-method)
  ;; Setup controls
  ;;
  ;; Since emacsy does all of the editing. We can use
  ;; overwrite mode which provides a block cursor.
  (set-source-theme! self (!theme self))
  (set-source-language! self "scheme")

  ;; https://developer.gnome.org/gtksourceview/stable/GtkSourceView.html
  (nomad-app-set-style self "textview { font-size: 10pt; }")

  (gtk-text-view-set-overwrite self #t)

  (when (and (!buffer self) (!parent self))
    (add-hook! (buffer-exit-hook (!buffer self))
               (lambda _
                 (gtk-widget-grab-focus (!parent self)))))

  (g-timeout-add 50 (lambda _
                      (unless emacsy-display-minibuffer?
                        (emacsy-tick))
                      (redisplay self)
                      #t)))

(define-method (redisplay (self <widget-source-view>))
  (set-source-text! self ((!thunk self)))
  (when (!buffer self)
    (set-source-point! self (buffer:point (!buffer self)))))



(define-class <widget-text-view> (<gtk-source-view>)
  (theme  #:accessor !theme  #:init-keyword #:theme  #:init-value "classic")
  (styles #:accessor !styles #:init-keywork #:styles #:init-value '()))

(define-method (initialize (self <widget-text-view>) args)
  (next-method)
  ;; Setup controls
  ;;
  ;; Since emacsy does all of the editing. We can use
  ;; overwrite mode which provides a block cursor.
  (gtk-text-view-set-overwrite self #t)
  (set-source-theme! self (!theme self))
  (set-source-language! self "scheme")


  ;; https://developer.gnome.org/gtksourceview/stable/GtkSourceView.html
  ;;                      "textview { font-family: Monospace; font-size: 10pt;}")
  (map (cut nomad-app-set-style self <>) (!styles self)))



(define-class <widget-border> (<gtk-drawing-area>))

(define-method (initialize (self <widget-border>) args)
  (next-method)
  (gtk-widget-set-size-request self -1 1)
  (connect self 'draw nomad-draw-border))



(define-class <widget-mini-popup> (<gtk-scrolled-window>)
  (!grid #:accessor !grid #:init-keyword #:child #:init-value #f))

(define-method (initialize (self <widget-mini-popup>) args)
  (next-method)

  ;; init slots
  (unless (!grid self)
    (set! (!grid self) (make <gtk-grid>)))

  ;; alignment and sizing
  (gtk-widget-set-size-request self -1 200)
  (gtk-widget-set-halign self 'fill)
  (gtk-widget-set-valign self 'end)

  ;; packing
  (let ((grid (make <gtk-grid>))
        (box  (make <gtk-vbox>)))
    (gtk-box-pack-start box (make <widget-border>) #f #f 0)
    (gtk-box-pack-start box grid #t #t 0)
    (gtk-box-pack-start box (make <widget-border>) #f #f 0)
    (gtk-container-add self box)
    (set! (!grid self) grid)))



;; These methods work on base GTK classes.
(define-method (set-source-theme! (self <gtk-source-view>) text)
  (let* ((buf     (gtk-text-view-get-buffer self))
         (manager (make <gtk-source-style-scheme-manager>))
         (style   (gtk-source-style-scheme-manager-get-scheme manager text)))
    (gtk-source-buffer-set-style-scheme buf style)))


(define-method (set-source-language! (self <gtk-source-view>) text)
  (let* ((buf     (gtk-text-view-get-buffer self))
         (manager (make <gtk-source-language-manager>))
         (lang    (gtk-source-language-manager-get-language manager text)))
    (gtk-source-buffer-set-language buf lang)))

(define-method (set-source-text! (self <gtk-source-view>) text)
  "Sets source @var{view} text buffer to @var{text}"
  (let ((buf (gtk-text-view-get-buffer self)))
    (gtk-text-buffer-set-text buf text -1)))

(define-method (set-source-point! (self <gtk-source-view>) pos)
  "Sets source @var{view} cursor point to @var{pos}"
  (let* ((buf (gtk-text-view-get-buffer self))
         (iter (gtk-text-buffer-get-start-iter buf)))
    (gtk-text-buffer-get-start-iter buf)
    (gtk-text-iter-forward-chars iter
                                (- pos 1))
    (gtk-text-buffer-place-cursor buf iter)))

(define-method (container-child (self <gtk-container>))
  (car (gtk-container-get-children self)))

(define-method (container-empty? (self <gtk-container>))
  (= (length (gtk-container-get-children self)) 0))
