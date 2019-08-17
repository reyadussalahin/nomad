;; webkit.scm
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

(define-module (test webkit)
  #:use-module (g-golf)
  #:use-module (srfi srfi-64))

(gi-import "Gtk")
(gi-import "WebKit2")

(test-skip "webkit")

(let ((gtk? (gtk-init-check #f #f)))
  (test-assert "Gtk init?" gtk?))

(test-group "webkit"
            (let* ((settings (webkit-network-proxy-settings-new "http://thou.shall.not.pass:8080"
                                                                '("*.gnu.org")))
                   (view (make <webkit-web-view>))
                   (view-context (webkit-web-view-get-context view))
                   (global-context (webkit-web-context-get-default))
                   (new-context (make <webkit-web-context>))
                   (bad-uri  "https://duckduckgo.com/")
                   (good-uri "https://www.gnu.org"))

              (test-assert (not (unspecified? context)))
              (test-assert (not (unspecified? view-context))) ;; Fails because view-context is unspecified
              (test-assert (not (unspecified? global-context))) ;; Fails because global-context is unspecified
              (test-equal <webkit-web-context> (class-of (slot-ref view 'web-context))) ;; Fails because its foreign

              ;; Can now set proxy for new context, but not useful since this
              ;; needs to apply either to a global context or a view's context
              (webkit-web-context-set-network-proxy-settings new-context 'custom settings)
   ))
