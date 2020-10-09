;; text.scm
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

(define-module (tests text)
  #:use-module (oop goops)
  #:use-module (nomad emacsy text)
  #:use-module (emacsy emacsy)
  #:use-module (unit-test))

(define-class <test-text> (<test-case>))

(define-method (test-lines (self <test-text>))
  (emacsy-initialize #t)
  (with-buffer scratch
    (goto-char (point-min))
    (assert-equal 2 (count-lines))
    (assert-equal 1 (line-number-at-pos))
    (forward-line)
    (assert-equal 2 (line-number-at-pos))
    (forward-line)
    (assert-equal 3 (line-number-at-pos))))