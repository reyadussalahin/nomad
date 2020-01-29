;; init.scm
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

(define-module (tests init)
  #:use-module (oop goops)
  #:use-module (nomad init)
  #:use-module (nomad util)
  #:use-module (unit-test))

(define-class <test-init> (<test-case>))

(define-method (test-init-ident (self <test-init>))
  (with-fluids ((fluid~ "/tmp/home"))
    (assert-equal "/tmp/home/.nomad" %user-init-file)
    (assert-equal <string> (class-of %user-init-file))
    (assert-equal "/tmp/home/.nomad.d" %user-nomad-directory)
    (assert-equal "/tmp/home/.nomad.d/session.scm" %session-file)
    (assert-equal "/tmp/home/.nomad.d/cookies.db" %user-cookie-file)))