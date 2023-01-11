;;;; -*- Mode: Lisp -*-

;;;; Luca Milanesi 886279

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defparameter null-value 'null)
(defparameter json-obj-value 'jsonobj)
(defparameter json-array-value 'jsonarray)

(defparameter dbl-quotes (char-code #\"))
(defparameter plus-sign (char-code #\+))
(defparameter minus-sign (char-code #\-))
(defparameter zero (char-code #\0))
(defparameter dot (char-code #\.))
(defparameter colon (char-code #\:))
(defparameter comma (char-code #\,))
(defparameter opn-brace (char-code #\{))
(defparameter cls-brace (char-code #\}))
(defparameter opn-sqr-bracket (char-code #\[))
(defparameter cls-sqr-bracket (char-code #\]))

(defparameter boolean-variable-list (list "true" "false" "null"))
(defparameter boolean-value-list (list T NIL null-value))

(defun is-ws (my-char)
  (if (not (null my-char))
      (or
       (eql my-char (char-code #\Space))
       (eql my-char (char-code #\Linefeed))
       (eql my-char (char-code #\Tab))
       (eql my-char (char-code #\Return))
       (eql my-char 0))
      NIL))

(defun is-zeronine (my-char)
  (if (not (null my-char))
      (and
       (>= my-char (char-code #\0))
       (<= my-char (char-code #\9)))
      NIL))

(defun is-sign(my-char)
  (if (not (null my-char))
      (or 
       (eql my-char (char-code #\-))
       (eql my-char (char-code #\+)))
      NIL))

(defun is-char-exp (my-char)
  (if (not (null my-char))
      (or 
       (eql my-char (char-code #\e))
       (eql my-char (char-code #\E)))
      NIL))

(defun is-escape (my-char)
  (if (not (null my-char))
      (or
       (eql my-char (char-code #\"))
       (eql my-char (char-code #\\))
       (eql my-char (char-code #\/))
       (eql my-char (char-code #\b))
       (eql my-char (char-code #\f))
       (eql my-char (char-code #\n))
       (eql my-char (char-code #\r))
       (eql my-char (char-code #\t)))
      NIL))

(defun is-escape-u (my-char)
  (if (not (null my-char))
      (eql my-char (char-code #\u))
      NIL))

(defun is-hex (my-char)
  (if (not (null my-char))
      (or 
       (is-zeronine my-char)
       (and
        (>= my-char (char-code #\A))
        (<= my-char (char-code #\F)))
       (and
        (>= my-char (char-code #\a))
        (<= my-char (char-code #\f))))
      NIL))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun call-error ()
  (error "syntax error"))

(defun trim-head (ascii-list)
  (let ((first-char (first ascii-list)))
    (cond
      ((is-ws first-char) (trim-head (rest ascii-list)))
      (T ascii-list))))

(defun string-to-ascii-list (string)
  (if (stringp string)
      (map 'list #'char-code string)
      (call-error)))

(defun ascii-list-to-string (ascii-list)
  (coerce (mapcar 'code-char ascii-list) 'string))

(defun calc-exponential (base exponent)
  (* base (expt 10 exponent)))

(defun ascii-list-to-floating (ascii-list)
  (let ((to-integer (ascii-list-to-integer ascii-list)))
    (float (* to-integer
	      (expt 10 (* -1 (length ascii-list)))))))

(defun ascii-list-to-integer (ascii-list)
  (if (null ascii-list)
      0
      (+ (* (expt 10 (- (length ascii-list) 1)) 
            (- (first ascii-list) (char-code #\0)))
         (ascii-list-to-integer (rest ascii-list)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-boolean - - ;

(defun json-boolean (json-list) 
  (parse-boolean-job 
   json-list boolean-variable-list boolean-value-list))

(defun parse-boolean-job (json-list record value)
  (let ((boolean-rest 
	 (parse-boolean json-list 
			(string-to-ascii-list (first record)))))
    (if (not (null boolean-rest))
        (cons (first value) (rest boolean-rest))
        (if (and (null (rest record)) (null (rest value)))
            NIL
            (parse-boolean-job json-list 
			       (rest record) (rest value))))))

(defun parse-boolean (json-list record)
  (if (null record)
      (cons T json-list)
      (if (eql (first json-list) (first record))
          (parse-boolean (rest json-list) (rest record))
          NIL)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-number - - ;

(defun json-number (json-list)
  (or (parse-my-exponential json-list)
      (parse-my-floating json-list)
      (parse-my-integer json-list)))

(defun parse-my-exponential (json-list)
  (let ((base-rest (parse-my-exponential-base json-list))) 
    (if (is-char-exp (first (rest base-rest)))
        (if (not (null (rest base-rest)))
            (if (is-char-exp (first (rest base-rest)))
                (if (not (null (cddr base-rest)))
                    (cond
                      ((eql (second (rest base-rest)) plus-sign)
                       (let ((exp-rest (digits 
					(cdddr base-rest))))
                         (cons
                          (calc-exponential 
                           (first base-rest) 
                           (ascii-list-to-integer (first exp-rest)))
                          (rest exp-rest))))
                      ((eql (second (rest base-rest)) 
                            minus-sign)
                       (let ((exp-rest (digits (cdddr base-rest))))
                         (cons
                          (calc-exponential
                           (first base-rest) 
                           (* -1 
                              (ascii-list-to-integer 
                               (first exp-rest))))
                          (rest exp-rest))))
                      ((not 
                        (is-sign (second (rest base-rest))))
                       (let ((exp-rest (digits (cddr base-rest))))
                         (cons
                          (calc-exponential 
                           (first base-rest)
                           (ascii-list-to-integer (first exp-rest)))
                          (rest exp-rest))))
                      (T NIL))
                    NIL)
                NIL)
            NIL)
        NIL)))

(defun parse-my-exponential-base (json-list)
  (or (parse-my-floating json-list)
      (parse-my-integer json-list)))

(defun parse-my-floating (json-list)
  (let ((integer-rest (parse-my-integer json-list)))
    (if (eql (first (rest integer-rest)) dot)
        (let ((floating-rest (digits (cddr integer-rest))))
          (let ((floating-part
                 (ascii-list-to-floating (first floating-rest))))
            (if (>= (first integer-rest) 0)
                (cons (+
                       (first integer-rest) 
                       floating-part)
                      (rest floating-rest))
                (cons (- (first integer-rest) floating-part)
                      (rest floating-rest)))))
        NIL)))

(defun parse-my-integer (json-list)
  (if (null json-list)
      (call-error)
      (if (eql (first json-list) minus-sign)
          (let ((number-rest (digit 
			      (rest json-list))))
            (if (not (null (first number-rest)))
                (cons 
                 (* -1 (ascii-list-to-integer (first number-rest)))
                 (rest number-rest))))
          (let ((number-rest (digit json-list))) 
            (if (not (null (first number-rest)))
                (cons 
                 (ascii-list-to-integer (first number-rest))
                 (rest number-rest)))))))

(defun digit (json-list)
  (if (eql (first json-list) zero)
      (cons (list (first json-list)) 
            (rest json-list))
      (let ((num (digits json-list)))
        (if (not (null (first num)))
            num
            NIL))))

(defun digits (json-list)
  (if (null json-list)
      (call-error)
      (if (is-zeronine (first json-list))
          (let ((ret-value (digits (rest json-list))))
            (cons
             (cons (first json-list) (first ret-value))
             (rest ret-value)))
          (cons NIL json-list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-string - - ;

(defun json-string (json-list)
  (if (and (eql (first json-list) dbl-quotes)
           (not (null (rest json-list))))
      (let ((string-rest 
             (parse-string (rest json-list))))
        (cons 
         (ascii-list-to-string (first string-rest))
         (rest string-rest)))
      NIL))

(defun parse-string (json-list)
  (cond ((eql (first json-list) dbl-quotes)
         (cons NIL (rest json-list)))
        ((null json-list)
         (call-error))
        (T (if (eql (first json-list) (char-code #\\))
               (if (not (null 
			 (parse-escape (rest json-list))))
                   (let ((ret-value 
			  (parse-string (cddr json-list))))
                     (cons
                      (cons (first json-list) 
                            (cons (second json-list) 
                                  (first ret-value)))
                      (rest ret-value)))
                   (if (not (null 
			     (parse-escape-u (rest json-list))))
                       (let ((ret-value 
                              (parse-string
			       (cddr (cddddr json-list)))))
                         (cons
                          (cons
			   (first json-list) 
			   (cons
			    (second json-list) 
			    (cons
			     (third json-list) 
			     (cons
			      (fourth json-list)
			      (cons
			       (fifth json-list) 
			       (cons
				(sixth json-list)
				(first ret-value)))))))
                          (rest ret-value)))
                       (call-error)))
               (let ((ret-value (parse-string (rest json-list))))
                 (cons
                  (cons (first json-list) (first ret-value))
                  (rest ret-value)))))))

(defun parse-escape (json-list)
  (if (not (null json-list))
      (if (is-escape (first json-list))
          T
          NIL)
      NIL))

(defun parse-escape-u (json-list)
  (if (not (null json-list))
      (if (is-escape-u (first json-list))
          (if (and (is-hex (second json-list))
                   (is-hex (third json-list))
                   (is-hex (fourth json-list))
                   (is-hex (fifth json-list)))
              T
              NIL)
          NIL)
      NIL))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-value - - ;

(defun json-value (json-list)
  (or (json-object (trim-head json-list))
      (json-string (trim-head json-list))
      (json-number (trim-head json-list))
      (json-boolean (trim-head json-list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-pair - - ;

(defun json-pair (json-list)
  (let ((attributes-rest (json-string (trim-head json-list))))
    (let ((trim-rest (trim-head (rest attributes-rest))))
      (if (not (null trim-rest))
          (if (eql (first trim-rest) colon)
              (let ((value-rest 
                     (json-value (trim-head (rest trim-rest)))))
                (if (not (null value-rest))
                    (cons 
                     (list 
                      (first attributes-rest) (first value-rest))
                     (trim-head (rest value-rest)))
                    (call-error)))
              (call-error))
          (call-error)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-elements - - ;

(defun json-elements (json-list)
  (let ((value-rest (json-value (trim-head json-list))))
    (let ((trim-rest (trim-head (rest value-rest))))
      (if (not (null trim-rest))
          (if (eql (first trim-rest) comma)
              (let ((elements-rest 
                     (json-elements (trim-head (rest trim-rest)))))
                (cons 
                 (append 
                  (list (first value-rest)) 
                  (first elements-rest))
                 (rest elements-rest)))
              (cons (list (first value-rest)) trim-rest))
          (call-error)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-members - - ;

(defun json-members (json-list)
  (let ((pair-rest (json-pair (trim-head json-list))))
    (let ((trim-rest (trim-head (rest pair-rest))))
      (if (not (null trim-rest))
          (if (eql (first trim-rest) comma)
              (let ((members-rest 
                     (json-members (trim-head (rest trim-rest)))))
                (cons 
                 (append 
                  (list 
                   (first pair-rest)) 
                  (first members-rest))
                 (rest members-rest)))
              (cons (list (first pair-rest)) trim-rest))
          (call-error)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-array - - ;

(defun json-array (json-list)
  (let ((trim-json-list (trim-head json-list)))
    (if (eql (first trim-json-list) opn-sqr-bracket)
        (let ((after-bracket (trim-head (rest trim-json-list))))
          (if (not (null after-bracket))
              (if (eql (first after-bracket) cls-sqr-bracket)
                  (cons (list json-array-value) NIL)
                  (let ((elements-rest 
			 (json-elements (trim-head after-bracket))))
                    (if (eql 
			 (first (rest elements-rest)) 
			 cls-sqr-bracket)
                        (cons 
                         (append 
                          (list 
                           json-array-value) 
                          (first elements-rest))
                         (trim-head (cddr elements-rest)))
                        (call-error))))
              (call-error)))
        NIL)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-obj - - ;

(defun json-obj (json-list)
  (let ((trim-json-list (trim-head json-list)))
    (if (eql (first trim-json-list) opn-brace)
        (let ((after-brace (trim-head (rest trim-json-list))))
          (if (not (null after-brace))
              (if (eql (first after-brace) cls-brace)
                  (cons (list json-obj-value) NIL)
                  (let ((members-rest 
			 (json-members (trim-head after-brace))))
                    (if (eql (first (rest members-rest)) cls-brace)
                        (cons 
                         (append 
                          (list 
                           json-obj-value) 
                          (first members-rest)) 
                         (trim-head (cddr members-rest)))
                        (call-error))))
              (call-error)))
        NIL)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - json-object - - ;

(defun json-object (json-list)
  (or (json-obj (trim-head json-list))
      (json-array (trim-head json-list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - jsonparse - - ;

(defun jsonparse (json-string)
  (if (stringp json-string)
      (let ((json-rest (json-object (trim-head
				     (string-to-ascii-list json-string)))))
        (if (null (trim-head (rest json-rest)))
            (first json-rest)
            (call-error)))
      (call-error)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - jsonaccess - - ;

(defun jsonaccess (json &rest fields)
  (if (null json)
      (call-error)
      (if (null fields)
          (if (eql (first json) json-array-value)
              (call-error)
              json)
          (cond ((eql (first json) json-obj-value)
                 (if (stringp (first fields))
                     (let ((field 
			    (pair-finder (rest json) (first fields))))
                       (if (not (null field))
                           (call-back-jsonaccess field (rest fields))
                           (call-error)))
                     (call-error)))
                ((eql (first json) json-array-value)
                 (if (numberp (first fields))
                     (let ((field (nth (first fields) (rest json))))
                       (if (not (null field))
                           (call-back-jsonaccess field (rest fields))
                           (call-error)))
                     (call-error)))
                (T (call-error))))))

(defun call-back-jsonaccess (field fields)
  (if (null fields)                       
      field
      (apply #'jsonaccess field fields)))

(defun pair-finder (json field)
  (if (null json)
      NIL
      (if (string= (first (first json)) field)
          (second (first json))
          (pair-finder (rest json) field))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - jsonread - - ;

(defun jsonread (filename) 
  (with-open-file (stream filename
			  :direction :input
			  :if-does-not-exist :error)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      (jsonparse contents))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; - - jsondump - - ;

(defun jsondump (json filename)
  (with-open-file (stream filename
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (format stream (json-object-write json)))
  filename)

(defun json-object-write (json)
  (if (listp json)
      (cond ((equal json-obj-value (first json))
             (concatenate 'string 
			  "{ " 
			  (json-obj-write (rest json)) 
			  " }"))
            ((equal json-array-value (first json))
             (concatenate 'string 
			  "[ " 
			  (json-array-write (rest json))
			  " ]"))
            (T (call-error)))
      (call-error)))

(defun json-obj-write (json-obj)
  (if (null json-obj)
      NIL
      (json-members-write json-obj)))

(defun json-array-write (json-array)
  (if (null json-array)
      NIL
      (json-elements-write json-array)))

(defun json-members-write (json-members)
  (cond ((null (rest json-members)) 
         (json-pair-write (first json-members)))
        (T (concatenate 'string 
			(json-pair-write (first json-members))
			", "
			(json-members-write (rest json-members))))))

(defun json-elements-write (json-elements)
  (cond ((null (rest json-elements)) 
         (json-value-write (first json-elements)))
        (T (concatenate 'string 
			(json-value-write (first json-elements)) 
			", "
			(json-elements-write (rest json-elements))))))

(defun json-pair-write (json-pair)
  (if (stringp (first json-pair))
      (concatenate 'string (json-string-write (first json-pair))
		   " : "
		   (json-value-write (second json-pair)))
      (call-error)))

(defun json-value-write (json-value)
  (cond 
    ((stringp json-value)
     (json-string-write json-value))
    ((numberp json-value) 
     (write-to-string json-value))
    ((eql json-value T)
     (concatenate 'string "true"))
    ((eql json-value NIL)
     (concatenate 'string "false"))
    ((eql json-value null-value)
     (concatenate 'string "null"))
    (T (json-object-write json-value))))

(defun json-string-write (json-string)
  (concatenate 'string "\"" json-string "\""))
