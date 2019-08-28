(define-module (gnu packages nomad))

(use-modules
 (guix packages)
 (guix git-download)
 (guix gexp)
 (guix download)
 (guix build-system gnu)
 (guix build-system glib-or-gtk)
 ((guix licenses) #:prefix license:)
 (guix utils)
 (gnu packages autotools)
 (gnu packages bash)
 (gnu packages curl)
 (gnu packages gettext)
 (gnu packages glib)
 (gnu packages gnome)
 (gnu packages gnupg)
 (gnu packages gtk)
 (gnu packages guile-xyz)
 (gnu packages guile)
 (gnu packages password-utils)
 (gnu packages pkg-config)
 (gnu packages tls)
 (gnu packages texinfo)
 (gnu packages webkit)
 (gnu packages xdisorg)
 (gnu packages xorg)
)

(define %source-dir (dirname (current-filename)))

(load (string-append %source-dir "/g-golf.scm"))
(use-modules (gnu packages g-golf))

(define-public emacsy-git
  (let ((commit "ed88cfbe57d5a40ea4e1604bfdc61f10ff750626"))
    (package (inherit emacsy)
             (name "emacsy-git")
             (version (git-version "0.4.1" "5" commit))
             (source (origin (method git-fetch)
                             (uri (git-reference (url "https://git.savannah.gnu.org/git/emacsy.git")
                                                 (commit commit)))
                             (file-name (string-append name "-" version))
                             (sha256 (base32 "05zgpdh997q53042w192xdzgnfv6ymmkb16xkgd0ssj5pnnccj28")))))))

(define-public nomad
  (package
    (name "nomad")
    (version "v0.1.2-candidate")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://git.savannah.gnu.org/git/nomad.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1h0gjzl6h9zzifqghdxzv7zir3gwh024821ppc3ajsm8gnjzq4a7"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("bash" ,bash)
       ("pkg-config" ,pkg-config)
       ("libtool" ,libtool)
       ("guile" ,guile-2.2)
       ("glib:bin" ,glib "bin")
       ("texinfo" ,texinfo)
       ("perl" ,perl)))
    (inputs
     `(("guile" ,guile-2.2)
       ("guile-lib" ,guile-lib)
       ("guile-gcrypt" ,guile-gcrypt)
       ("guile-readline" ,guile-readline)
       ("gnutls" ,gnutls)
       ("shroud" ,shroud)
       ("emacsy" ,emacsy-minimal)
       ("glib" ,glib)
       ("dbus-glib" ,dbus-glib)
       ("gtk+" ,gtk+)
       ("gtksourceview" ,gtksourceview)
       ("webkitgtk" ,webkitgtk)
       ("xorg-server" ,xorg-server)))
    (propagated-inputs
     `(("glib" ,glib)
       ("glib-networking" ,glib-networking)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)))
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 popen)
                  (ice-9 rdelim)
                  (srfi srfi-26))
       #:phases
       (modify-phases %standard-phases
         (add-before 'check 'start-xorg-server
           (lambda* (#:key inputs #:allow-other-keys)
             ;; The test suite requires a running X server.
             (system (format #f "~a/bin/Xvfb :1 &"
                             (assoc-ref inputs "xorg-server")))
             (setenv "DISPLAY" ":1")
             #t))
         (add-after 'install 'wrap-binaries
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (gio-deps (map (cut assoc-ref inputs <>) '("glib-networking"
                                                               "glib")))
                    (gio-mod-path (map (cut string-append <> "/lib/gio/modules")
                                       gio-deps))
                    (effective (read-line (open-pipe*
                                           OPEN_READ
                                           "guile" "-c"
                                           "(display (effective-version))")))
                    (deps (map (cut assoc-ref inputs <>)
                               '("emacsy" "guile-lib" "guile-readline"
                                 "shroud")))
                    (scm-path (map (cut string-append <>
                                        "/share/guile/site/" effective)
                                   `(,out ,@deps)))
                    (go-path (map (cut string-append <>
                                       "/lib/guile/" effective "/site-ccache")
                                  `(,out ,@deps)))
                    (progs (map (cut string-append out "/bin/" <>)
                                '("nomad"))))
               (map (cut wrap-program <>
                         `("GIO_EXTRA_MODULES" ":" prefix ,gio-mod-path)
                         `("GUILE_LOAD_PATH" ":" prefix ,scm-path)
                         `("GUILE_LOAD_COMPILED_PATH" ":"
                           prefix ,go-path))
                    progs)
               #t))))))
    (inputs
     `(("guile" ,guile-2.2)
       ("gnupg" ,gnupg)
       ("xclip" ,xclip)))))

(define-public nomad
  (let ((commit "1a1bb61048cfc34b83d388e38b5612d369a2b9df"))
    (package
      (name "nomad")
      (version (git-version "0.0.4-alpha" "375" commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://git.savannah.gnu.org/git/nomad.git")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1a4am9ak98y0p3ibiji14lr99lqplis08lka2kz0zyqalh4y8c68"))))
      (build-system gnu-build-system)
      (native-inputs
       `(("autoconf" ,autoconf)
         ("automake" ,automake)
         ("pkg-config" ,pkg-config)
         ("libtool" ,libtool)
         ("guile" ,guile-2.2)
         ("glib:bin" ,glib "bin")))
      (inputs
       `(("atk" ,atk)
         ("guile" ,guile-2.2)
         ("guile-lib" ,guile-lib)
         ("guile-gcrypt" ,guile-gcrypt)
         ("g-golf" ,g-golf)
         ("gobject-introspection" ,gobject-introspection)
         ("guile-readline" ,guile-readline)
         ("pango" ,pango)
         ("libsoup" ,libsoup)
         ("gdk-pixbuf" ,gdk-pixbuf)
         ("gnutls" ,gnutls)
         ("shroud" ,shroud-0.1.2)
         ;; waiting on shroud to be updated in guix
         ("emacsy" ,emacsy-git)
         ;; emacsy needs to be updated in guix
         ("glib" ,glib)
         ("dbus-glib" ,dbus-glib)
         ("webkitgtk" ,webkitgtk)
         ("xorg-server" ,xorg-server)))
      (propagated-inputs
       `(("glib-networking" ,glib-networking)
         ;; propergate packages that have typelibs
         ("gtksourceview" ,gtksourceview)
         ("gtk+" ,gtk+)
         ("gsettings-desktop-schemas"
          ,gsettings-desktop-schemas)))
      (arguments
       `(#:tests? #t
         #:modules ((guix build gnu-build-system)
                    (guix build utils)
                    (ice-9 popen)
                    (ice-9 rdelim)
                    (srfi srfi-26))
         #:phases
         (modify-phases %standard-phases
           (add-before 'configure 'setenv
             (lambda* (#:key inputs #:allow-other-keys)
               (let ((g-golf (string-append (assoc-ref inputs "g-golf") "/lib/"))
                     (typelib (lambda (input)
                               (string-append (assoc-ref inputs input) "/lib/girepository-1.0"))))
                 (setenv "LD_LIBRARY_PATH" g-golf)
                 (setenv "GI_TYPELIB_PATH" (string-append (getcwd) "/guile" ":"
                                                          (typelib "gtk+") ":"
                                                          (typelib "gtksourceview") ":"
                                                          (typelib "pango") ":"
                                                          (typelib "gdk-pixbuf") ":"
                                                          (typelib "atk") ":"
                                                          (typelib "webkitgtk") ":"
                                                          (typelib "libsoup"))))
               #t))
           (add-before 'check 'start-xorg-server
                     (lambda* (#:key inputs #:allow-other-keys)
                       ;; The test suite requires a running X server.
                       (system (format #f "~a/bin/Xvfb :1 &"
                                       (assoc-ref inputs "xorg-server")))
                       (setenv "DISPLAY" ":1")
                       #t))
           (add-after 'install 'wrap-binaries
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (gio-deps (map (cut assoc-ref inputs <>) '("glib-networking" "glib")))
                      (gio-mod-path (map (cut string-append <> "/lib/gio/modules") gio-deps))
                      (effective (read-line (open-pipe* OPEN_READ
                                                        "guile" "-c"
                                                        "(display (effective-version))")))
                      (deps (map (cut assoc-ref inputs <>) '("emacsy" "guile-lib"
                                                             "guile-readline" "shroud" "g-golf")))
                      (deps-typelibs (map (cut assoc-ref inputs <>)
                                          '("gtksourceview" "gtk+" "pango" "gdk-pixbuf"
                                            "atk" "webkitgtk" "libsoup")))
                      (scm-path (map (cut string-append <>
                                          "/share/guile/site/" effective)
                                     `(,out ,@deps)))
                      (go-path (map (cut string-append <>
                                         "/lib/guile/" effective "/site-ccache")
                                    `(,out ,@deps)))
                      (typelibs (map (cut string-append <> "/lib/girepository-1.0")
                                     `(,out ,@deps-typelibs)))
                      (progs (map (cut string-append out "/bin/" <>)
                                  '("nomad"))))
                 (map (cut wrap-program <>
                           `("GIO_EXTRA_MODULES" ":" prefix ,gio-mod-path)
                           `("GUILE_LOAD_PATH" ":" prefix ,scm-path)
                           `("GUILE_LOAD_COMPILED_PATH" ":"
                             prefix ,go-path)
                           `("LD_LIBRARY_PATH" ":" prefix
                             ,(list (string-append (assoc-ref inputs "g-golf") "/lib")))
                           `("GI_TYPELIB_PATH" ":" prefix ,typelibs))
                      progs)
                 #t))))))
      (native-search-paths
       (list (search-path-specification
              (variable "GI_TYPELIB_PATH")
              (separator ":")
              (files '("lib/girepository-1.0")))
             ))
      (home-page "https://savannah.nongnu.org/projects/nomad/")
      (synopsis "Web Browser extensible in Guile scheme")
      (description "Nomad is a Emacs-like web browser that consists of a small
C backend and modular feature-set fully programmable in Guile.")
      (license license:gpl3+))))
