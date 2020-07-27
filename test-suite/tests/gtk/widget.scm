;; widget.scm
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

(define-module (tests gtk widget)
  #:use-module (g-golf)
  #:use-module (nomad nomad)
  #:use-module (nomad gtk gtk)
  #:use-module (unit-test)
  #:duplicates (merge-generics replace warn-override-core warn last))

(eval-when (expand load eval)
  (map (match-lambda ((namespace item)
                      (gi-import-by-name namespace item)))
       '(("Gtk" "init")
         ("Gtk" "Container"))))

(define-class <test-widget> (<test-case>))

(define-method (test-container (test <test-widget>))
  (gtk-init 0 #f)
  (let ((window (make <gtk-window>))
        (label  (make <gtk-label> #:label "test-label")))
    (assert-true (container-empty? window))
    (gtk-container-add window label)
    (assert-false (container-empty? window))
    (assert-equal `(,label) (gtk-container-get-children window))))