;;
;; rm.lisp - Delete files and directories.
;;

(defpackage :rm
  (:documentation "Delete files and directories.")
  (:use :cl :opsys)
  (:export
   #:rm
   #:rmdir
   #:!rm
   #:!rmdir
   ))
(in-package :rm)

(defun rmdir (dir &key parents)
  "Remove directory DIR. If PARENTS is true, remove the parent directories in
the path."
  (nos:delete-directory dir)
  (when parents
    (loop
       :with splitsville = (split-path dir)
       :with parent-list = (if (path-absolute-p dir)
			       (cdr splitsville) ;; Don't try to delete root.
			       splitsville)
       :for dir :in parent-list
       :do (nos:delete-directory dir))))

#+lish
(lish:defcommand rmdir
  ((parents boolean :short-arg #\p
    :help "True to delete the parent directories if they are empty.")
   (dirs directory :optional nil :repeating t :help "Directories to delete."))
  "Delete directories."
  (loop :for dir :in dirs
     :do (rmdir dir :parents parents))
  (values))

(defun rm (path)
  "Remove a file."
  (delete-file path))

#+lish
(lish:defcommand rm
  ((force boolean :short-arg #\f
    :help "True to try to delete files even if you don't have write permission.")
   ;; @@@ I don't want to do this until everything is much better tested.
   ;; (recursive boolean :short-arg #\r
   ;;  :help "True to delete directories recursively.")
   (files pathname :optional nil :repeating t :help "Files to delete."))
  "Delete directories."
  (declare (ignore force))
  (loop :for file :in files
     :do
     (if (probe-directory file)
	 (rmdir file)
	 (rm file)))
  (values))

;; EOF
