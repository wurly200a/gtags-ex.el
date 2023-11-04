;;; gtags-ex.el -- extend gtags for Emacs

;; Author: Wurly, May 2007
;; Version: 0.03

;;; Install:

;; Put this file into load-path'ed directory.
;; And put these expressions into your ~/.emacs.
;;
;;   ;---- gtags-ex ----
;;   (when (locate-library "gtags-ex")
;;     (require 'gtags-ex)
;;     (global-set-key "\C-cgu" 'gtags-ex-update)
;;     )
;;
;;    (defadvice save-buffer (after after-save-buffer ())
;;      "after save-buffer process"
;;      (progn
;;        (gtags-ex-update-on-background))
;;    )
;;    (ad-activate 'save-buffer)
;;

;;; History:
;; 2007.05.23          (ver 0.01) | new
;; 2007.05.24          (ver 0.02) | use asynchronous process
;; 2007.06.02          (ver 0.03) | use pop-to-buffer on gtags-ex-update()

;;; Code:

(provide 'gtags-ex)

(defconst gtags-ex-buffer-name "*gtags-ex-command*")
(defconst gtags-ex-process-name "gtags-ex-command-process")
(defconst gtags-ex-output-buffer-name "*gtags-ex-output*")
(defvar gtags-ex-window-configuration nil)
(defvar gtags-ex-command-str nil)
(defvar gtags-ex-command-opt-str nil)
(defvar gtags-ex-pop-to-buffer-mode nil)

; internal function
; start asynchronous process
(defun gtags-ex-command-async()
  "use async shell"
  (setq gtags-ex-window-configuration (current-window-configuration))
  (prog1
      (save-current-buffer
        (save-selected-window
          (start-process gtags-ex-process-name nil gtags-ex-command-str gtags-ex-command-opt-str)
          (set-process-sentinel (get-process gtags-ex-process-name) 'gtags-ex-sentinel)
          (if (not gtags-ex-pop-to-buffer-mode)
              (get-buffer-create gtags-ex-output-buffer-name)
            (pop-to-buffer gtags-ex-output-buffer-name) )
          (set-process-filter (get-process gtags-ex-process-name) 'gtags-ex-command-output)
          (setq truncate-lines nil
                buffer-read-only nil)
          (set-buffer gtags-ex-output-buffer-name)
          (goto-char (point-max))
          (insert (concat ">"
                          gtags-ex-command-str " "
                          gtags-ex-command-opt-str " \n"))
          ))
    )
  )

;filter function for process
(defun gtags-ex-command-output (process output)
  (with-current-buffer (set-buffer gtags-ex-output-buffer-name)
    (goto-char (point-max))
    (insert output)
    )
)

;sentinel for process
(defun gtags-ex-sentinel (process event)
  (with-current-buffer (set-buffer gtags-ex-output-buffer-name)
    (goto-char (point-max))
    (insert (concat "global: " (car (split-string event "\n"))))
    (insert "\n")
    )
  (if (string-equal event "finished\n")
      (progn
        (sit-for 1) ; wait 1sec
        (message "global update finished"))
    )
  )

(defun gtags-ex-update ()
  "global update"
  (interactive)
  (setq gtags-ex-command-str "global.exe")
  (setq gtags-ex-command-opt-str "-uv")
  (setq gtags-ex-pop-to-buffer-mode t)
  (gtags-ex-command-async)
  )

(defun gtags-ex-update-on-background ()
  "global update on background"
  (interactive)
  (setq gtags-ex-target-file-name (car (split-string (buffer-name) "<")))
  (if (or (string-match ".+\.c$" gtags-ex-target-file-name)
          (string-match ".+\.h$" gtags-ex-target-file-name)
          (string-match ".+\.cpp$" gtags-ex-target-file-name)
          (string-match ".+\.hpp$" gtags-ex-target-file-name) )
      (progn
        (setq gtags-ex-command-str "global.exe")
        (setq gtags-ex-command-opt-str "-uv")
        (setq gtags-ex-pop-to-buffer-mode nil)
        (gtags-ex-command-async)
        ))
  )

;;; gtags-ex.el ends here
