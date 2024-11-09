;;; company-extra.el --- Addional commands for company -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/company-extra
;; Version: 0.1.0
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (company "1.0.0"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; company-extra.el provides additional functionality for the company-mode
;; completion framework in Emacs.

;; Currently it includes commands to navigate completion candidates and
;; automatically display their documentation.

;;; Code:




(require 'company)

(defcustom company-extra-doc-delay 0.1
  "Delay in seconds before showing documentation popup.

Specifies the delay in seconds before showing the documentation for a completion
candidate in the completion menu.

A numeric value representing the time to wait. A lower value makes the
documentation appear more quickly, while a higher value introduces a longer
delay. The default is 0.1 seconds.

Adjusting this value can be useful for controlling the responsiveness of the
documentation popup, especially in environments where generating documentation
is computationally expensive or when using slower machines."
  :group 'company-extra
  :type 'number)

(defvar-local company-extra--debounce-timer nil)

(defun company-extra--run-in-buffer (buffer timer-sym fn &rest args)
  "Run a function FN in a BUFFER and cancel timer TIMER-SYM.

Argument TIMER-SYM is a symbol that represents a timer.
Argument BUFFER is the buffer in which the function/macro will be executed.
Argument FN is the function or macro that will be executed.
Argument ARGS is a list of additional arguments that will be passed to the FN."
  (when (and buffer (buffer-live-p buffer))
    (with-current-buffer buffer
      (let ((wnd (get-buffer-window buffer)))
        (if wnd
            (with-selected-window wnd
              (apply fn args))
          (apply fn args)))
      (company-extra--cancel-timer timer-sym))))

(defun company-extra--cancel-timer (timer-sym)
  "Cancel a timer if it exists and set the value of TIMER-SYM to nil.

Argument TIMER-SYM is a symbol that represents the timer to be canceled."
  (when-let* ((timer-value (symbol-value timer-sym)))
    (when (timerp timer-value)

      (cancel-timer timer-value)
      (set timer-sym nil))))

(defun company-extra--debounce (timer-sym delay fn &rest args)
  "Debounce execution FN with ARGS for DELAY.
TIMER-SYM is a symbol to use as a timer."
  (company-extra--cancel-timer timer-sym)
  (set timer-sym (apply #'run-with-idle-timer delay nil
                        #'company-extra--run-in-buffer
                        (current-buffer)
                        timer-sym
                        fn
                        args)))


;;;###autoload
(defun company-extra-select-next-and-show-doc (&optional arg)
  "Select next completion candidate and show its documentation.

With ARG, move by that many elements.
When `company-selection-default' is nil, add a special pseudo candidates
meant for no selection."
  (interactive "p")
  (when (company-manual-begin)
    (let ((selection (+ (or arg 1)
                        (or company-selection
                            company-selection-default
                            -1))))
      (company-set-selection selection)
      (company-show-doc-buffer)
      (company-extra--debounce 'company-extra--debounce-timer
                               company-extra-doc-delay
                               (lambda ()
                                 (ignore-errors
                                   (company-show-doc-buffer)))))))

;;;###autoload
(defun company-extra-select-previous-and-show-doc (&optional arg)
  "Select previous completion candidate and show its documentation.

Optional argument ARG specifies the number of candidates to move backward."
  (interactive "p")
  (company-extra-select-next-and-show-doc (if arg (- arg) -1)))

;;;###autoload
(defun company-extra-manual-begin-or-other-backend ()
  "Invoke manual completion or switch to another backend."
  (interactive)
  (let ((message-log-max nil)
        (inhibit-message t))
    (or
     (company-manual-begin)
     (company-other-backend))))

;;;###autoload
(defun company-extra-select-next ()
  "Display current company backend and switch to the next one."
  (interactive)
  (minibuffer-message (format "company backend: %s" company-backend))
  (funcall-interactively #'company-other-backend))



(provide 'company-extra)
;;; company-extra.el ends here