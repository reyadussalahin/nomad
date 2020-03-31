;; window.scm
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

(define-module (nomad gtk window)
  #:use-module (nomad gtk gi)
  #:use-module (srfi srfi-26)
  #:use-module (oop goops)
  #:use-module (emacsy emacsy)
  #:use-module (emacsy window)
  #:use-module (nomad web)
  #:use-module (nomad text)
  #:use-module (nomad gtk widget)
  #:use-module (nomad gtk frame)
  #:use-module (nomad gtk buffers)
  #:use-module (g-golf)
  #:export (<widget-window>
            widget-container
            window-widget))



(define-class <widget-window> (<window>)
  (last-tick #:accessor last-tick #:init-value -1))

(define-method (window-widget (window <widget-window>))
  (!widget (user-data window)))

(define-method (widget-container (window <widget-window>))
  (!container (user-data window)))

(define-method (widget-buffer (window <widget-window>))
  (!buffer (user-data window)))



(define-public (window-config-change window)
   (container-replace (!root (current-frame)) (instantiate-window root-window)))

;; Redisplay current window on each event read. This is mainly used to redisplay the
;; cursor.
;; (add-hook! read-event-hook (lambda (x)
;;                              (set! %redisplay? #t)
;;                              ;; (dimfi current-window)
;;                              ;; (window-config-change root-window)
;;                              ))


(add-hook! window-configuration-change-hook window-config-change)



(define (make-gtk-window list vertical)
  (let ((box (if vertical
                 (make <gtk-vbox>)
                 (make <gtk-hbox>))))
    (for-each (lambda (widget)
                (if  (!parent widget)
                    (begin
                      (gtk-container-remove (!parent widget) widget)
                      (gtk-box-pack-start box widget #t #t 0))
                    (gtk-box-pack-start box widget #t #t 0))) list)
    (gtk-widget-show-all box)
    box))

(define-method (instantiate-window (window <widget-window>))
  (make <window-container> #:window window #:buffer (window-buffer window)))

(define-method (instantiate-window (window <internal-window>))
  (make-gtk-window (map instantiate-window (window-children window))
                   (eq? (orientation window) 'vertical)))



(define-method (redisplay (window <internal-window>))
  (for-each redisplay (window-children window)))

(define-method (redisplay (window <window>))
  (when (is-a? (window-buffer window) <text-buffer>)
   (catch 'no-such-local-variable
     (lambda _
       (local-var 'widget))
     (lambda (key . vals)
       (set! (local-var 'widget) #f)))))

(define-method (redisplay (window <widget-window>))
  (next-method)
  (let* ((buffer    (window-buffer window))
         (view      (user-data window))
         (container (widget-container window))
         (widget    (cond ((is-a? buffer <widget-buffer>)
                           (buffer-widget buffer))
                          ((is-a? buffer <text-buffer>)
                           (local-var 'widget))
                          (else (error "Buffer not implimented")))))
    (unless widget
      (dimfi "CREATE")
      (cond
       ((is-a? buffer <widget-buffer>)
        (set! widget (make-buffer-widget buffer))
        (set! (buffer-widget buffer) widget))
       ((is-a? buffer <text-buffer>)
        (set! widget (make <widget-text-view> #:buffer buffer)))
       (else (error "Buffer not implimented")))
      (set! (!buffer (user-data window)) buffer)
      (set! (local-var 'widget) widget)
      (container-replace container widget)
      (run-hook %thunk-view-hook))

    (when (not (eq? buffer (!buffer (user-data window))))
      (dimfi "SWITCH")
      (set! (!buffer (user-data window)) buffer)
      (container-replace container widget)
      (run-hook %thunk-view-hook))))

(define-method (needs-redisplay? (widget <widget-text-view>) (window <widget-window>))
         (let* ((buffer (window-buffer window))
                (buffer-tick (buffer-modified-tick buffer))
                (window-tick (last-tick window)))
           (dimfi (or (not (= buffer-tick window-tick))
                (!thunk widget)))))

(define-method (redisplayed! (window <widget-window>))
  (let* ((buffer (window-buffer window))
         (buffer-tick (buffer-modified-tick buffer)))
    (set! (last-tick window) buffer-tick)))

;; (define-method (redisplay (self <nomad-gtk-window>))
;;   (let* ((buffer    (window-buffer self)))

;;     (when (not (eq? (!last-buffer self) buffer))
;;       (dimfi "Remove control" last-buffer)
;;       (set! (!last-tick self) -1)
;;       (set! (user-data self) #f))

;;     (when (needs-redisplay? self)
;;     (dimfi "Redisplay" (user-data self) buffer)
;;       (cond
;;        ((is-a? buffer <text-buffer>)
;;         (when (not (user-data self))
;;           (dimfi "Create control")
;;           (set! (user-data self) (make <widget-text-view>)))
;;         (set-source-text! (user-data self) (buffer:buffer-string buffer))
;;         (set-source-point! (user-data self) (buffer:point buffer)))
;;        ((is-a? buffer <gtk-widget-buffer>)
;;         (when (not (user-data self))
;;           (set! (user-data self) buffer)))
;;        (else
;;         (error (format #t "user-data for class-of: ~a Not implemented"
;;                        (class-of buffer))))))
;;     (redisplayed! self)
;;     ;; Make sure the window contains the control
;;     (set-child self)
;;     (set! (!last-buffer self) buffer)))

