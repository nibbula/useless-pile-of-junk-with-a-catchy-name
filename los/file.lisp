;;;
;;; file.lisp - WTF is this file?
;;;

(defpackage :file
  (:documentation "I can't believe you.")
  (:use :cl :dlib :dlib-misc :magic :grout :table)
  (:export
   #:describe-content-type
   #:!file
   ))
(in-package :file)

(declaim #.`(optimize ,.(getf los-config::*config* :optimization-settings)))

(defun print-content-type (thing type &key full (stream t))
  "Print the content type to STREAM. TYPE should be magic:content-type
structure. If FULL is true print all the data, otherwise just print the
description."
  (if full
      (progn
	(print-properties
	 (append `((file . ,thing))
		 (mapcar (_ (cons _ (funcall
				     (symbolify (s+ "content-type-" _)
						:package :magic) type)))
			 '(name category description file-name-match encoding
			   properties)))
	 :stream stream)
	(terpri))
      (format stream "~a~%" (content-type-description type))))

(defparameter *signal-errors* nil
  "True to signal file errors instead of printing them.")

(defun safer-guess-file-type (file &key device-contents-p)
  (if (not *signal-errors*)
      (handler-case
	  (guess-file-type file :device-contents-p device-contents-p)
	((or stream-error file-error opsys:opsys-error) (c)
	  (finish-output)
	  (let ((*print-pretty* nil))
	    (format *error-output*
		    ;; "~a: ~a ~a~%" file (type-of c) c))
		    "~a ~a~%" (type-of c) c))
	  (invoke-restart 'continue)))
      (guess-file-type file :device-contents-p device-contents-p)))

(defun describe-content-type (thing &key full (stream t) device-contents-p)
  "Describe the content type of THING to STREAM. THING can be a pathname
designator, or a vector of (unsigned-byte 8). If FULL is true print all the
data, otherwise just print the description. If DEVICE-CONTENTS-P is true, try
to read the contents of the device, otherwise just return the device type based
on metadata."
  (let ((type
	 (typecase thing
	   ((or pathname string)
	    (safer-guess-file-type thing :device-contents-p device-contents-p))
	   ((or stream (vector (unsigned-byte 8)))
	    (guess-content-type thing)))))
    (when type
      (print-content-type thing type :full full :stream stream))
    type))

(defmacro with-restarts (&body body)
  `(restart-case
       (progn
	 ,@body)
     (continue ()
       :report "Skip this file.")
     (skip-all ()
       :report "Skip remaining files with errors."
       (setf *signal-errors* nil))))

#+lish
(lish:defcommand file
  ;; BUG: we should be able to specify :optional nil and not get FILES twice
  ;; in the arg list.
  ((full boolean :short-arg #\f
    :help "True to show more information about the file.")
   (brief boolean :short-arg #\b :help "Don't output file names.")
   (device-contents-p boolean :short-arg #\d
    :help "Examine the contents of device files.")
   (collect boolean :short-arg #\c
    :help "True to set *output* to a sequence of content-type structures.")
   (table boolean :short-arg #\T :help "*output* to a table.")
   (files pathname #|:optional nil XXX |# :repeating t
    :help "Files to identify.")
   (signal-errors boolean :short-arg #\E
    :help "True to signal errors instead of just printing them."))
  :accepts (or sequence pathname string)
  "Try to guess what a file is."
  (with-grout ()
    (let ((*signal-errors* signal-errors)
	  results)
      (labels ((do-file-list (file-list)
		 (cond
		   ((or full brief)
		     (loop :for f :in file-list :do
			(with-restarts
			    (push (list f (describe-content-type
					   f :full full
					   :device-contents-p device-contents-p))
				  results))))
		   (t
		    (grout-print-table
		     (make-table-from
		      (loop
			 :with type
			 :for f :in file-list
			 :when (setf type
				     (with-restarts (safer-guess-file-type
						     f :device-contents-p
						     device-contents-p)))
			 :collect
			 (list (s+ f ":")
			       (progn
				 (push (list f type)
				       results)
				 (content-type-description
				  (second (car results)))))))
		     #| :trailing-spaces nil |#
		     :print-titles nil)))))
	(when lish:*input*
	  (do-file-list
	      (if (listp lish:*input*) lish:*input* (list lish:*input*))))
	(if files
	    (do-file-list files)
	    ;; (when (not lish:*input*)
	    ;;   (grout-format "You should probably supply a file name to guess ~
	    ;; 		   the content of.~%"))
	    (when (not lish:*input*)
	      ;; @@@ This might only work if *standard-input* is bi-valent?!
	      (let ((content
		     (slurp *standard-input* :element-type '(unsigned-byte 8))))
		(push (list "*standard-input*"
			    (describe-content-type content :full full
						   :device-contents-p
						   device-contents-p))
		      results))))
	(when (or collect table)
	  (setf results (nreverse results))
	  (setf lish:*output*
		(if table
		    (make-table-from
		     (loop :for r :in results
			:collect
			(let ((tt (second r)))
			  (vector (first r)
				   (content-type-name tt)
				   (content-type-category tt)
				   (content-type-description tt)
				   (content-type-file-name-match tt)
				   (content-type-encoding tt)
				   (content-type-properties tt))))
		     :columns
		     '((:name "File")
		       (:name "Type")
		       (:name "Category")
		       (:name "Description")
		       (:name "Match")
		       (:name "Encoding")
		       (:name "Properties")))
		    results)))))))

;; EOF
