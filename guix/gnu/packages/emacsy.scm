(define-module (gnu packages emacsy)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (gnu packages guile-xyz))

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
