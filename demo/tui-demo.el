;;; tui-demo.el --- Demo-related logic


;;; Commentary:
;; 

(require 'tui-core)

;;; Code:

(define-derived-mode tui-demo-mode special-mode "Tui Demo"
  "Major mode for viewing tui component previews."
  (setq-local buffer-read-only t)
  (setq-local revert-buffer-function
              (lambda (ignore-auto noconfirm) (tui-force-update (tui-root-node)))))

(put 'tui-demo-mode 'mode-class 'special)

(defun tui-show-component-demo (content)
  "Display demo CONTENT in a dedicated buffer."
  (setq content (tui--normalize-node content))
  (if (eq (tui--object-class content) 'tui-buffer)
      (progn
        (tui-render-element content)
        (switch-to-buffer
         (plist-get (tui--get-props content) :buffer)))
    (let ((buffer (format "*%s Demo*" (symbol-name (tui--object-class content)))))
      (tui-render-element
       (tui-buffer :buffer buffer
                :mode #'tui-demo-mode
                content))
      (switch-to-buffer buffer))))

(tui-define-component hello
  :render
  (lambda ()
    (let ((name (plist-get (tui-get-props) :name)))
      (list (format "Hello, %s!\n" name)
            "How are you?"))))

(tui-define-component basic-question
  :render
  (lambda ()
    "What do you want to work on today?"))

(tui-define-component my-message
  :documentation
  "Message containing other components"
  :render
  (lambda ()
    (let ((name (plist-get (tui-get-props) :name)))
      (list (hello :name name)
            "\n------------\n"
            (basic-question)
            "\nmake "
            (basic-counter :start-value 0)
            " widgets!"))))

;; (defvar tui-test-keymap
;;   (let ((map (make-sparse-keymap)))
;;     (define-key map [down-mouse-1] #'tui-confirmation)
;;     (define-key map [mouse-1] #'tui-confirmation)
;;     map))

(tui-define-component basic-counter
  :documentation
  "Basic counter control"
  :get-initial-state
  (lambda ()
    (or (plist-get (tui-get-props) :start-value)
        0))
  :render
  (lambda ()
    (lexical-let ((counter (tui-get-state))
                  (component component))
      (cl-flet ((incr-counter () (interactive) (tui--set-state component (+ 1 counter)))
                (decr-counter () (interactive) (tui--set-state component (- counter 1))))
        (list counter
              " "
              (propertize "⏶"
                          'keymap
                          ;;`(keymap (down-mouse-1 . ,(lambda () (interactive) (tui-set-state 5)))))
                          `(keymap (down-mouse-1 . ,#'incr-counter)))
              (propertize "⏷"
                          'keymap
                          `(keymap (down-mouse-1 . ,#'decr-counter))))))))

(provide 'tui-demo)

;;; tui-demo.el ends here
