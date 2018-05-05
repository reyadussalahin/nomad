(define-module (nomad init)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 pretty-print)
  #:use-module (nomad keymap)
  #:use-module (nomad events)
  #:use-module (nomad util)
  #:export (init run-tests user-init-file user-nomad-directory user-cookie-file))

(define user-init-file
  (string-append (home-dir) file-name-separator-string ".nomad.scm"))

(define user-nomad-directory
  (string-append (home-dir) file-name-separator-string ".nomad.d"))

(define user-cookie-file
  (string-append user-nomad-directory file-name-separator-string "cookies.db"))

(define (run-tests)
  (pretty-print (all-threads))
  (current-thread))

(define (init)
  (add-hook! key-press-hook handle-key-press)
  (add-hook! key-press-hook debug-key-press)
  (add-hook! event-hook debug-event)
  (format #t "~a\n" user-nomad-directory)
  (if (file-exists? user-nomad-directory)
      (info (format #f "creating ~a" user-nomad-directory))
      (mkdir user-nomad-directory #o755))
  (if (file-exists? user-init-file)
      (load user-init-file)))