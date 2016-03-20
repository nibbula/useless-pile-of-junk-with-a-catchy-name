;;;								-*- Lisp -*-
;;; char-picker.asd -- System definition for char-picker
;;;

(defpackage :char-picker-system
    (:use :common-lisp :asdf))

(in-package :char-picker-system)

(defsystem char-picker
    :name               "char-picker"
    :description        "Pick a character."
    :version            "0.1.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- gmail.com>"
    :license            "GPLv3"
    :source-control	:git
    :long-description   "Pick a character."
    :depends-on (:stretchy :char-util :keymap :curses :inator :fui)
    :components
    ((:file "char-picker")))