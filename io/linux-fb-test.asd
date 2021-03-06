;;;								-*- Lisp -*-
;;; linux-fb-test.asd - System definition for linux-fb-test
;;;

(defsystem linux-fb-test
    :name               "linux-fb-test"
    :description        "Tests for Linux framebuffer"
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- uucp!gmail.com>"
    :license            "GPL-3.0-only"
    :source-control	:git
    :long-description   "Tests for Linux framebuffer"
    :depends-on (:dlib :linux-fb :terminal :image :glob)
    :components
    ((:file "linux-fb-test")))
