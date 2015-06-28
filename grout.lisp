;;
;; grout.lisp - grumble grumble
;;

;; This is so we can make old fashioned command line utilities that can use a
;; few output features when they're available, but fall back to plain text
;; when not. This is not for making fancy interactive applications. It's just
;; for relatively simple output.

;; $Revision$

(defpackage :grout
  (:documentation "Generic Rectilinear Output And Text")
  (:use :cl :dlib :dlib-misc :opsys :ansiterm)
  (:export
   #:grout #:grout-stream
   #:dumb #:ansi #:ansi-stream #:slime
   #:grout-width
   #:grout-height
   #:grout-bold
   #:grout-set-bold
   #:grout-underline
   #:grout-set-underline
   #:grout-set-normal
   #:grout-color
   #:grout-set-color
   #:grout-clear
   #:grout-beep
   #:grout-object
   #:grout-write
   #:grout-format
   #:grout-finish
   #:grout-done
   #:make-grout
   #:with-grout
   ))
(in-package :grout)

(defparameter *colors*
  #(:black :red :green :yellow :blue :magenta :cyan :white nil :default))

(defclass grout ()
  ((stream
    :initarg :stream :accessor grout-stream  
    :documentation "The stream for output."))
  (:documentation "Generic output destination."))

(defgeneric grout-width (grout)
  (:documentation "Return the width of the output, or NIL for infinite or
unknown."))

(defgeneric grout-height (grout)
  (:documentation "Return the width of the output, or NIL for infinite or
unknown."))

(defgeneric grout-bold (grout string)
  (:documentation "Output the string boldly."))

(defgeneric grout-set-bold (grout flag)
  (:documentation "Turn bold on or off."))

(defgeneric grout-underline (grout string)
  (:documentation "Output the string underlined."))

(defgeneric grout-set-underline (grout flag)
  (:documentation "Turn underlining on or off."))

(defgeneric grout-set-normal (grout)
  (:documentation "Return output to normal. No attributes. No color."))

(defgeneric grout-color (grout foreground background string)
  (:documentation "Output the string with the colors set."))

(defgeneric grout-set-color (grout foreground background)
  (:documentation "Set the color."))

(defgeneric grout-clear (grout)
  (:documentation "Clear the screen."))
    
(defgeneric grout-beep (grout)
  (:documentation "Do something annoying."))

(defgeneric grout-object (grout object)
  (:documentation "Output the object in a way that it might be accesible."))

(defgeneric grout-write (grout object
			 &key
			   array base case circle escape gensym length level
			   lines miser-width pprint-dispatch pretty radix
			   readably right-margin
			   &allow-other-keys)
  (:documentation "Write an object to the grout."))

(defgeneric grout-format (grout format-string &rest format-args)
  (:documentation "Formatted output to the grout."))

(defgeneric grout-finish (grout)
  (:documentation "Make any pending output be sent to the grout."))

(defgeneric grout-done (grout)
  (:documentation "Be done with the grout."))

;; If you need a specific one, just make it yourself.
(defun make-grout (&optional (stream *standard-output*))
  "Return an appropriate grout instance. Try to figure out what kind to make
from the STREAM. STREAM defaults to *STANDARD-OUTPUT*."
  (cond
    ((has-terminal-attributes stream)
     (make-instance 'ansi :stream stream))
    ((and (nos:getenv "EMACS")
	  (find-package :slime))
     ;; @@@ should really test the stream
     (make-instance 'slime :stream stream))
    (t
     (make-instance 'dumb :stream stream))))

(defmacro with-grout ((var &optional stream) &body body)
  "Evaluate the body with a GROUT bound to output."
  `(let (,var)
     (unwind-protect
	(progn
	  (setf ,var (make-grout (or ,stream *standard-output*)))
	  ,@body)
       (when ,var (grout-done ,var)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dumb all over. A little ugly on the side.

(defclass dumb (grout)
  ()
  (:documentation "Can't do nothing special."))

(defmethod grout-width ((g dumb))
  "Return the width of the output, or NIL for infinite or unknown."
  (declare (ignore g))
  (let ((col (nos:getenv "COLUMNS")))
    (or (and col (parse-integer col)) 80)))

(defmethod grout-height ((g dumb))
  "Return the width of the output, or NIL for infinite or unknown."
  (declare (ignore g))
  (let ((rows (nos:getenv "ROWS")))
    (or (and rows (parse-integer rows)) 24)))

(defmethod grout-bold ((g dumb) string)
  "Output the string boldly."
  (write-string string (grout-stream g)))

(defmethod grout-set-bold ((g dumb) flag)
  "Turn bold on or off."
  (declare (ignore g flag)))

(defmethod grout-underline ((g dumb) string)
  "Output the string underlined."
  (write-string string (grout-stream g)))

(defmethod grout-set-underline ((g dumb) flag)
  "Turn underlining on or off."
  (declare (ignore g flag)))

(defmethod grout-set-normal ((g dumb))
  "Return output to normal. No attributes. No color."
  (declare (ignore g)))

(defmethod grout-color ((g dumb) foreground background string)
  "Set the color."
  (declare (ignore foreground background))
  (write-string string (grout-stream g)))

(defmethod grout-set-color ((g dumb) foreground background)
  "Set the color."
  (declare (ignore g foreground background)))

(defmethod grout-clear ((g dumb))
  "Clear the screen."
  (dotimes (n (grout-height g))
    (write-char #\newline (grout-stream g))))
    
(defmethod grout-beep ((g dumb))
  "Do something annoying."
  (write-char #\^G (grout-stream g))
  (finish-output (grout-stream g)))

(defmethod grout-object ((g dumb) object)
  "Output the object in a way that it might be accesible."
  (write-string (princ-to-string object) (grout-stream g)))

(defmethod grout-write ((g dumb) object &rest args 
			 &key
			   (array            *print-array*)
			   (base             *print-base*)
			   (case             *print-case*)
			   (circle           *print-circle*)
			   (escape           *print-escape*)
			   (gensym           *print-gensym*)
			   (length           *print-length*)
			   (level            *print-level*)
			   (lines            *print-lines*)
			   (miser-width      *print-miser-width*)
			   (pprint-dispatch  *print-pprint-dispatch*)
			   (pretty           *print-pretty*)
			   (radix            *print-radix*)
			   (readably         *print-readably*)
			   (right-margin     *print-right-margin*)
			   &allow-other-keys)
  (declare (ignorable array base case circle escape gensym length level
		      lines miser-width pprint-dispatch pretty radix
		      readably right-margin))
  (apply #'write object :stream (grout-stream g) args))

(defmethod grout-format ((g dumb) format-string &rest format-args)
  (apply #'format (grout-stream g) format-string format-args))

(defmethod grout-finish ((g dumb))
  (finish-output (grout-stream g)))

(defmethod grout-done ((g dumb))
  "Be done with the grout."
  (declare (ignore g)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ANSI is a bad word.

(defclass ansi (grout)
  ((term
    :initarg :term :accessor ansi-term
    :documentation "The terminal."))
  (:documentation "Can do everything in ansiterm package."))

(defmethod initialize-instance
    :after ((o ansi) &rest initargs &key &allow-other-keys)
  "Initialize a ansi."
  (declare (ignore initargs))
  (setf (slot-value o 'term) (make-instance 'terminal))
  (terminal-start (slot-value o 'term)))

(defmethod grout-width ((g ansi))
  "Return the width of the output, or NIL for infinite or unknown."
  (terminal-window-columns (ansi-term g)))

(defmethod grout-height ((g ansi))
  "Return the width of the output, or NIL for infinite or unknown."
  (terminal-window-rows (ansi-term g)))

(defmethod grout-bold ((g ansi) string)
  "Output the string boldly."
  (with-slots (term) g
    (tt-bold term t)
    (tt-write-string term string)
    (tt-bold term nil)))

(defmethod grout-set-bold ((g ansi) flag)
  "Turn bold on or off."
  (tt-bold (ansi-term g) flag))

(defmethod grout-underline ((g ansi) string)
  "Output the string underlined."
  (with-slots (term) g
    (tt-underline term t)
    (tt-write-string term string)
    (tt-underline term nil)
    (tt-finish-output term)))

(defmethod grout-set-underline ((g ansi) flag)
  "Turn underlining on or off."
  (tt-underline (ansi-term g) flag))

(defmethod grout-set-normal ((g ansi))
  "Return output to normal. No attributes. No color."
  (tt-normal (ansi-term g)))

(defmethod grout-color ((g ansi) foreground background string)
  "Set the color."
  (with-slots (term) g
    (tt-color term foreground background)
    (tt-write-string term string)
    (tt-color term :default :default)))

(defmethod grout-set-color ((g ansi) foreground background)
  "Set the color."
  (tt-color (ansi-term g) foreground background))

(defmethod grout-clear ((g ansi))
  "Clear the screen."
  (tt-clear (ansi-term g)))

(defmethod grout-beep ((g ansi))
  "Do something annoying."
  (tt-beep (ansi-term g)))

(defmethod grout-object ((g ansi) object)
  "Output the object in a way that it might be accesible."
  (tt-write-string (ansi-term g) (princ-to-string object)))

(defmethod grout-write ((g ansi) object &rest args 
			 &key
			   (array            *print-array*)
			   (base             *print-base*)
			   (case             *print-case*)
			   (circle           *print-circle*)
			   (escape           *print-escape*)
			   (gensym           *print-gensym*)
			   (length           *print-length*)
			   (level            *print-level*)
			   (lines            *print-lines*)
			   (miser-width      *print-miser-width*)
			   (pprint-dispatch  *print-pprint-dispatch*)
			   (pretty           *print-pretty*)
			   (radix            *print-radix*)
			   (readably         *print-readably*)
			   (right-margin     *print-right-margin*)
			   &allow-other-keys)
  (declare (ignorable array base case circle escape gensym length level
		      lines miser-width pprint-dispatch pretty radix
		      readably right-margin))
  (tt-write-string (ansi-term g)
		   (with-output-to-string (str)
		     (apply #'write object :stream str args))))

(defmethod grout-format ((g ansi) format-string &rest format-args)
  (apply #'tt-format (ansi-term g) format-string format-args))

(defmethod grout-finish ((g ansi))
  (tt-finish-output (ansi-term g)))

(defmethod grout-done ((g ansi))
  "Be done with the grout."
  (tt-finish-output (ansi-term g))
  (terminal-done (ansi-term g)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Slime, with worms.

;; There must be a way to do these things with:
;;
;; (swank:eval-in-emacs '(save-excursion (set-buffer ".emacs") (piggy)))
;;
;; First we have to make the output go, then we have to set an overlay.
;;  (overlay-put (make-overlay beg end buffer) 'face 'underline)
;;  (overlay-put (make-overlay beg end buffer) 'face 'bold)

(defmacro swank (func &rest args)
  "So we don't have to depend on swank."
  `(if (find-package :swank)
       (funcall (intern ,(symbol-name func) (find-package :swank)) ,@args)
       (warn "You should probably load Swank.")))

(defclass slime (grout)
  ()
  (:documentation "Can just tell emacs to do something."))

(defmethod grout-width ((g slime))
  "Return the width of the output, or NIL for infinite or unknown."
  (swank eval-in-emacs '(window-width)))

(defmethod grout-height ((g slime))
  "Return the width of the output, or NIL for infinite or unknown."
  (swank eval-in-emacs '(window-height)))

(defmethod grout-bold ((g slime) string)
  "Output the string boldly."
  (write-string string (grout-stream g)))

(defmethod grout-set-bold ((g slime) flag)
  "Turn bold on or off."
  (declare (ignore g flag)))

(defmethod grout-underline ((g slime) string)
  "Output the string underlined."
  (write-string string (grout-stream g)))

(defmethod grout-set-underline ((g slime) flag)
  "Turn underlining on or off."
  (declare (ignore g flag)))

(defmethod grout-set-normal ((g slime))
  "Return output to normal. No attributes. No color."
  (declare (ignore g)))

(defmethod grout-color ((g slime) foreground background string)
  "Output the string with the colors set."
  (declare (ignore foreground background))
  (write-string string (grout-stream g)))

(defmethod grout-set-color ((g slime) foreground background)
  "Set the color."
  (declare (ignore g foreground background)))

(defmethod grout-clear ((g slime))
  "Clear the screen."
  (declare (ignore g)))
    
(defmethod grout-beep ((g slime))
  "Do something annoying."
  (swank eval-in-emacs '(ding t)))

(defmethod grout-object ((g slime) object)
  "Output the object in a way that it might be accesible."
  (swank present-repl-results (list object)))

(defmethod grout-write ((g slime) object &rest args
			 &key
			   (array            *print-array*)
			   (base             *print-base*)
			   (case             *print-case*)
			   (circle           *print-circle*)
			   (escape           *print-escape*)
			   (gensym           *print-gensym*)
			   (length           *print-length*)
			   (level            *print-level*)
			   (lines            *print-lines*)
			   (miser-width      *print-miser-width*)
			   (pprint-dispatch  *print-pprint-dispatch*)
			   (pretty           *print-pretty*)
			   (radix            *print-radix*)
			   (readably         *print-readably*)
			   (right-margin     *print-right-margin*)
			   &allow-other-keys)
  (declare (ignorable array base case circle escape gensym length level
		      lines miser-width pprint-dispatch pretty radix
		      readably right-margin))
  (apply #'write object :stream (grout-stream g) args))

(defmethod grout-format ((g slime) format-string &rest format-args)
  (apply #'format (grout-stream g) format-string format-args))

(defmethod grout-finish ((g slime))
  (finish-output (grout-stream g)))

(defmethod grout-done ((g slime))
  "Be done with the grout."
  (declare (ignore g)))

;; EOF