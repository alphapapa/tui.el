;;; tui-icon.el --- Icon helper component

;;; Commentary:
;; 

(require 'tui-core)


;;; Code:

(defvar all-the-icons-font-families)
(declare-function all-the-icons--family-name "all-the-icons.el")
(declare-function all-the-icons--data-name "all-the-icons.el")

(defvar tui--all-the-icons-size-data
  (make-hash-table :test #'equal)
  "Icon size data (WIDTH . HEIGHT).  Keys formatted as (FAMILY . ICON-NAME).")


(defun tui-build-icon-dimension-data ()
  "Build a database of rendered icon dimensions."
  (interactive)
  (require 'all-the-icons)
  (save-current-buffer
    (let ((buffer (get-buffer-create "*icon-indexing*"))
          (test-scaling-factor 10.0))
      (switch-to-buffer buffer)
      (erase-buffer)
      (let ((line-height (line-pixel-height))
            (char-width (progn (insert " ")
                               (tui-segment-pixel-width (point-min) (point-max)))))
        (erase-buffer)
        (mapc
         (lambda (family)
           (let ((family-name (funcall (all-the-icons--family-name family)))
                 (data-alist (funcall (all-the-icons--data-name family))))
             (mapcar
              (-lambda ((name . icon))
                (insert (propertize icon 'font-lock-ignore t 'face (list :height test-scaling-factor)))
                (puthash (cons family name)
                         (cons (/ (tui-segment-pixel-width (point-min) (point-max)) (* char-width test-scaling-factor))
                               (/ (line-pixel-height) (* line-height test-scaling-factor)))
                         tui--all-the-icons-size-data)
                (erase-buffer))
              data-alist)))
         all-the-icons-font-families))
      (kill-buffer buffer))))

;; TODO: keep consistent with resized display
;; TODO: consider use of multiple characters for displaying an icon (ex: position a wide icon across two characters)
;; TODO: implement a manual scaling mechanism
;; TODO: note that tui-icon requires all-the-icons
(tui-define-component tui-icon
  :documentation "Currently only serves icons included in the package `all-the-icons'.

Example:
(tui-icon
 :icon-set 'faicon
 :icon-name \"barcode\"
 :scaling nil)"
  :prop-documentation
  (:icon-set (format "One of symbols (%s)" (mapconcat #'symbol-name all-the-icons-font-families ", "))
             :icon-name "Name of the desired icon as a string"
             :scaling "Explicit scaling factor (a number).  Default value is t- indicating that the icon should be scaled to reside within a single monospaced character.  nil indicates the icon should remain unscaled (preserve its default size).")
  :get-default-props
  (lambda ()
    '(:scaling t))
  :render
  (lambda ()
    ;; CLEANUP
    (when (hash-table-empty-p tui--all-the-icons-size-data)
      (tui-build-icon-dimension-data))
    (-let* ((props (tui-get-props))
            (icon-set (plist-get props :icon-set))
            (icon-name (plist-get props :icon-name))
            (scaling (plist-get props :scaling))
            ((scale-width . scale-height) (gethash (cons icon-set icon-name) tui--all-the-icons-size-data)))
      ;; TODO: improve on scaling algorithm
      ;;   - avoid making tall icons (use fixed-width w<1 and h/w>1)
      (propertize
       (assoc-default icon-name (funcall (all-the-icons--data-name icon-set)))
       'font-lock-ignore t
       'face (list (append (list :family (funcall (all-the-icons--family-name icon-set)))
                           (when scaling
                             (list :height (* (/ 1 scale-width)
                                              (if (eq scaling t)
                                                  1
                                                scaling))))))))))

(provide 'tui-icon)

;;; tui-icon.el ends here
