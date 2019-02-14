;;;								-*- Lisp -*-
;;; pager.asd -- System definition for pager
;;;

(defsystem pager
    :name               "pager"
    :description        "something like more or less"
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPLv3"
    :source-control	:git
    :long-description   "We can only see so much at one time."
    :depends-on (:dlib :opsys :dlib-misc :table-print :stretchy
		 :keymap :char-util :fatchar
		 #+use-re :re #-use-re :cl-ppcre
		 :terminal :fatchar-io
		 :rl :pick-list :utf8b-stream :fui :inator :terminal-inator
		 :terminal-table :completion)
    :entry-point "pager:standalone"
    :build-operation 'program-op
    :components
    ((:file "pager")))
