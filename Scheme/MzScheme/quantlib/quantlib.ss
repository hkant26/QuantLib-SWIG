
(require-library "file.ss" "dynext")
(load-extension (build-path (collection-path "quantlib") 
                            (append-extension-suffix "QuantLibc")))

; macros for making it easier to free memory
; careful: they could prevent tail-recursion!
(define-macro deleting-let
  (lambda (bindings . body)
    (let ((thunk (gensym))
          (result (gensym)))
      `(let ,(map (lambda (b) (list (car b) (cadr b))) bindings)
         (define ,thunk (lambda () ,@body))
         (let ((,result (,thunk)))
           ,@(map (lambda (b) (list (caddr b) (car b))) bindings)
           ,result)))))

(define-macro deleting-let*
  (lambda (bindings . body)
    (let ((thunk (gensym))
          (result (gensym)))
      `(let* ,(map (lambda (b) (list (car b) (cadr b))) bindings)
         (define ,thunk (lambda () ,@body))
         (let ((,result (,thunk)))
           ,@(map (lambda (b) (list (caddr b) (car b))) bindings)
           ,result)))))

; more scheme-like names which couldn't be set from SWIG

(define Calendar=? Calendar-equal)

(define Date=?  Date-equal)
(define Date<?  Date-less)
(define Date>?  Date-greater)
(define Date<=? Date-less-equal)
(define Date>=? Date-greater-equal)

(define DayCounter=? DayCounter-equal)

(define SampleNumber-value  SampleNumber-value-get)
(define SampleNumber-weight SampleNumber-weight-get)

(define Array+ Array-add)
(define Array- Array-sub)
(define (Array* a x)
  (if (number? x)
      (Array-mul-d a x)
      (Array-mul-a a x)))
(define Array/ Array-div)

(define Matrix+ Matrix-add)
(define Matrix- Matrix-sub)
(define Matrix* Matrix-mul)
(define Matrix/ Matrix-div)

(define TridiagonalOperator+ TridiagonalOperator-add)
(define TridiagonalOperator- TridiagonalOperator-sub)
(define TridiagonalOperator* TridiagonalOperator-mul)
(define TridiagonalOperator/ TridiagonalOperator-div)

; added functionality
(define (Calendar-advance . args)
  (if (integer? (caddr args))
      (apply Calendar-advance-units args)
      (apply Calendar-advance-period args)))


(define History-old-init new-History)
(define (new-History dates values)
  (let ((null (null-double)))
    (History-old-init dates
                      (map (lambda (x) (or x null)) values))))
(define (History-map h f)
  (let ((results '()))
    (History-for-each h (lambda (e)
                          (if e
                              (set! results (cons (f e) results))
                              (set! results (cons #f results)))))
    (reverse results)))
(define (History-map-valid h f)
  (let ((results '()))
    (History-for-each-valid h (lambda (e)
                                (set! results (cons (f e) results))))
    (reverse results)))

(define MarketElementHandle-old-init new-MarketElementHandle)
(define (new-MarketElementHandle . args)
  (let ((h (MarketElementHandle-old-init)))
    (if (not (null? args))
        (MarketElementHandle-link-to! h (car args)))
    h))

(define (TermStructure-discount self x . extrapolate)
  (let ((method #f))
    (if (number? x)
        (set! method TermStructure-discount-vs-time)
        (set! method TermStructure-discount-vs-date))
    (apply method self x extrapolate)))
(define (TermStructure-zero-yield self x . extrapolate)
  (let ((method #f))
    (if (number? x)
        (set! method TermStructure-zeroYield-vs-time)
        (set! method TermStructure-zeroYield-vs-date))
    (apply method self x extrapolate)))
(define (TermStructure-forward self x1 x2 . extrapolate)
  (let ((method #f))
    (if (number? x1)
        (set! method TermStructure-forward-vs-time)
        (set! method TermStructure-forward-vs-date))
    (apply method self x1 x2 extrapolate)))
(define (TermStructure-instantaneous-forward self x . extrapolate)
  (let ((method #f))
    (if (number? x)
        (set! method TermStructure-instantaneousForward-vs-time)
        (set! method TermStructure-instantaneousForward-vs-date))
    (apply method self x extrapolate)))

(define TermStructureHandle-old-init new-TermStructureHandle)
(define (new-TermStructureHandle . args)
  (let ((h (TermStructureHandle-old-init)))
    (if (not (null? args))
        (TermStructureHandle-link-to! h (car args)))
    h))

(define FlatForward-old-init new-FlatForward)
(define (new-FlatForward today settlement forward dayCounter)
  (if (number? forward)
      (deleting-let* ((m (new-SimpleMarketElement forward) 
                         delete-MarketElement)
                      (h (new-MarketElementHandle m) 
                         delete-MarketElementHandle))
        (FlatForward-old-init today settlement h dayCounter))
      (FlatForward-old-init today settlement forward dayCounter)))