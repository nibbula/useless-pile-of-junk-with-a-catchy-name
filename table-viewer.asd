;;;								-*- Lisp -*-
;;; table-viewer.asd - System definition for table-viewer
;;;

(defsystem table-viewer
    :name               "table-viewer"
    :description        "View tables."
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPLv3"
    :source-control	:git
    :long-description   "View tables."
    :depends-on (:dlib :collections :table :table-print :keymap :inator
		 :terminal :terminal-inator :dtt :char-util :fui :fatchar
		 :fatchar-io :grout)
    :components
    ((:file "table-viewer")))
