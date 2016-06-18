;;
;; inator.lisp - Generic UI applet
;;

;; Another try at just a simple ‘inator’. The way this works is hopefully
;; temporary until I get FT working.

(defpackage :inator
  (:documentation
"This is a little scaffolding for making a certain style of applet. The style
that's encouraged is what one might call ‘emacs-like’. I consider this as a
‘lesser’ Frobulator, in other words a style of interaction and editing that
can be applied to many types of data.

To make an app, you subclass INATOR and provide editing, input and display
methods. You can also provide a custom keymap. You can probably get by with
just providing methods for UPDATE-DISPLAY and AWAIT-EVENT, and then calling
EVENT-LOOP with an INATOR sub-class instance.

See FUI-INATOR for a curses based Inator. Despite it being well suited to
terminal interfaces, it seems like it might be rather ill advised to make
a TERM-INATOR.
")
  (:use :cl :keymap :char-util)
  (:export
   ;; Inator class
   #:inator
   #:inator-keymap
   #:inator-point
   #:inator-quit-flag
   #:inator-command
   #:inator-last-command
   ;; Commands
   #:next
   #:previous
   #:forward-unit
   #:backward-unit
   #:forward-multiple
   #:backward-multiple
   #:next-page
   #:previous-page
   #:move-to-beginning
   #:move-to-end
   #:move-to-top
   #:move-to-bottom
   #:search-command
   #:sort-command
   #:jump-command
   #:quit
   #:accept
   #:redraw
   #:cut
   #:copy
   #:paste
   #:select
   #:default-action
   ;; Output
   #:message
   #:help
   ;; Events
   #:event-loop
   #:update-display
   #:await-event
   #:process-event
   #:start-inator
   #:finish-inator
   #:*default-inator-keymap*
   ))
(in-package :inator)

(defclass inator ()
  ((keymap
    :initarg :keymap :accessor inator-keymap
    :documentation "What to do when a key is pressed.")
   (point
    :initarg :point :accessor inator-point
    :documentation "Where the action is.")
   (quit-flag
    :initarg :quit-flag :accessor inator-quit-flag :initform nil :type boolean
    :documentation "True to quit the inator.")
   (command
    :initarg :command :accessor inator-command :initform nil
    :documentation "The current command.")
   (last-command
    :initarg :last-command :accessor inator-last-command :initform nil
    :documentation "The last command."))
  (:documentation
   "Have some kind of editing style interaction."))

;; Navigation
(defgeneric next (inator))
(defgeneric previous (inator))
(defgeneric forward-unit (inator))
(defgeneric backward-unit (inator))
(defgeneric forward-multiple (inator))
(defgeneric backward-multiple (inator))
(defgeneric next-page (inator))
(defgeneric previous-page (inator))
(defgeneric move-to-beginning (inator))
(defgeneric move-to-end (inator))
(defgeneric move-to-top (inator))
(defgeneric move-to-bottom (inator))
(defgeneric search-command (inator))
(defgeneric sort-command (inator))
(defgeneric jump-command (inator)) ; or maybe leap?

;; Action
(defgeneric quit (inator)
  (:documentation "Quit the Inator.")
  (:method ((i inator)) (setf (inator-quit-flag i) t)))
(defgeneric accept (inator)
  (:documentation "Accept the data and usually exit."))
(defgeneric redraw (inator)
  (:documentation "Redraw the screen."))

;; Edit?
(defgeneric cut (inator))		; kill
(defgeneric copy (inator))
(defgeneric paste (inator))		; yank
(defgeneric select (inator))		; mark
(defgeneric default-action (inator))

;; Help / Output

(defgeneric message (inator format-string &rest args)
  (:documentation "Display a short message. Usually one line."))

(defgeneric help (inator)
  (:documentation "Display help, usually describing what keys do."))

;; Whole Inator functions
(defgeneric event-loop (inator))
(defgeneric update-display (inator))
(defgeneric await-event (inator))
(defgeneric process-event (inator event &optional keymap-in))
(defgeneric start-inator (inator))
(defgeneric finish-inator (inator))

;; Examples to consider:
;;  list picker
;;  file picker
;;  tree browser
;;  table browser
;;  puca (revision control frontend)
;;  pager

(defkeymap *default-inator-keymap*
  `((,(ctrl #\N)	. next)
    (,(ctrl #\P)	. previous)
    (,(ctrl #\F)	. forward-unit)
    (,(ctrl #\B)	. backward-unit)
    (,(meta-char #\F)	. forward-multiple)
    (,(meta-char #\B)	. backward-multiple)
    (,(ctrl #\V)	. next-page)
    (,(meta-char #\V)	. previous-page)
    (,(ctrl #\A)	. move-to-beginning)
    (,(ctrl #\E)	. move-to-end)
    (,(meta-char #\<)	. move-to-top)
    (,(meta-char #\>)	. move-to-bottom)
    (,(ctrl #\S)	. search-command)
    (,(meta-char #\s)	. sort-command)	; ?
    (,(meta-char #\j)	. jump-command)	; ?
    (,(ctrl #\L)	. redraw)
    (,(ctrl #\G)	. quit)
    (#\escape		. *default-inator-escape-keymap*)
    )
  :default-binding 'default-action)

(defparameter *default-inator-escape-keymap*
  (build-escape-map *default-inator-keymap*))

;; Default methods

(defmethod initialize-instance
    :after ((o inator) &rest initargs &key &allow-other-keys)
  "Initialize a inator."
  (declare (ignore initargs))
  (when (not (slot-boundp o 'keymap))
    (setf (slot-value o 'keymap) *default-inator-keymap*)))

(defmethod start-inator ((inator inator))
  "Default method which does nothing."
  (declare (ignore inator)))

(defmethod finish-inator ((inator inator))
  "Default method which does nothing."
  (declare (ignore inator)))

(defmethod process-event ((inator inator) event &optional keymap-in)
  "Default way to process an event."
  (with-slots (command last-command keymap) inator
    (setf last-command command
	  command (key-definition event (or keymap-in keymap)))
    (flet ((apply-symbol (s &optional args)
	     (if (typep (symbol-function s) 'generic-function)
		 (if (compute-applicable-methods (symbol-function s)
						 (cons inator args))
		     (apply s inator args)
		     (message inator "(~S) has no applicable methods." s))
		 (apply s inator args))))
      (cond
	((not command)
	 (message inator "Event ~a is not bound in keymap ~w."
		  event keymap)
	 (return-from process-event))
	;; a list to apply
	((consp command)
	 (if (fboundp (car command))
	     (apply-symbol (car command) (cdr command))
	     (message inator "(~S) is not defined." (car command))))
	;; something represted by a symbol
	((symbolp command)
	 (cond
	   ((fboundp command)		; a function
	    (apply-symbol command))
	   ((keymap-p (symbol-value command)) ; a keymap
	    (process-event inator (await-event inator) (symbol-value command)))
	   (t				; anything else
	    (message inator "Key binding ~S is not a function or a keymap."
		     command))))
	;; a function object
	((functionp command)
	 (funcall command inator))
	(t				; anything else is an error
	 (error "Weird thing in keymap: ~s." command))))))

(defmethod event-loop ((inator inator))
  "The default event loop. Using this loop a sub-class only has to supply the
UPDATE-DISPLAY and and AWAIT-EVENT methods."
  (unwind-protect
       (progn
	 (start-inator inator)
	 (update-display inator)
	 (loop :with event
	    :do
	    (setf event (await-event inator))
	    (process-event inator event)
	    :while (not (inator-quit-flag inator))
	    :do
	    (update-display inator)))
    (finish-inator inator)))

;; EOF
