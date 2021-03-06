;;;								-*- Lisp -*-
;;; misc.asd - System definition for misc
;;;

(defsystem misc
    :name               "misc"
    :description        "Miscellaneous small commands."
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPL-3.0-only"
    :source-control	:git
    :long-description   "Miscellaneous small commands."
    :depends-on (:dlib :opsys :collections :glob :table :terminal :lish :grout
		 :los-util :dlib-misc)
    :components
    ((:file "misc")))
