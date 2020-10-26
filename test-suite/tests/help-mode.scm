;; help-mode.scm
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

(define-module (tests help-mode)
  #:use-module (oop goops)
  #:use-module (nomad help-mode)
  #:use-module (nomad views)
  #:use-module (unit-test))

(define-class <test-help> (<test-case>))

(define-method (test-routes (self <test-help>))
  (assert-equal 4 (length %routes))
  (let ((view (match-route "/describe/object/%load-path" %routes)))
    (assert-true view)
    (assert-equal 'describe-object-view (procedure-name view))))
