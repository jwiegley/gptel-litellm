;;; gptel-litellm --- Helper code for using GPTel with LiteLLM -*- lexical-binding: t -*-

;; Copyright (C) 2025 John Wiegley

;; Author: John Wiegley <johnw@gnu.org>
;; Created: 20 Jun 2025
;; Version: 1.0
;; Keywords: ai gptel tools
;; X-URL: https://github.com/jwiegley/dot-emacs

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; gptel-litellm provides seamless integration with LiteLLM backends by
;; automatically handling session ID management in GPTel conversations.
;;
;; Features:
;; - Generates unique UUIDv1 session IDs per buffer
;; - Injects session IDs into API requests when using matching backends
;; - Uses configurable regex to identify LiteLLM-compatible backends
;;
;; Usage:
;; - Call `gptel-litellm-install-sessions' to enable session tracking. Session
;;   IDs are then automatically added to requests using the :litellm_session
;;   request parameter
;;
;; Customization:
;; - `gptel-litellm-backend-name-re' controls which backends receive
;;   session IDs (default matches "LiteLLM")
;;
;; Designed to work transparently through hooks into GPTel's mode and request
;; processing pipeline. No direct calls to the internal functions are needed
;; for normal usage.

;;; Code:

(require 'cl-lib)
(require 'gptel)
(require 'uuidgen)

(defgroup gptel-litellm nil
  "Helper library for working with LiteLLM backends."
  :group 'gptel)

(defcustom gptel-litellm-backend-name-re "LiteLLM"
  "*Regular expressions matching LiteLLM backends."
  :type 'regexp
  :group 'gptel-litellm)

(defvar gptel-litellm--session-id nil)

(defun gptel-litellm-set-session-id ()
  "Set the session-id for the current buffer to a generated UUID."
  (setq-local gptel-litellm--session-id (uuidgen-1)))

(defun gptel-litellm-add-litellm-session (fsm)
  "If backend is LiteLLM, based on the given FSM, add a session-id.
See `gptel-litellm-backend-name-re', which identifies when a backend is
LiteLLM."
  (when (string-match-p gptel-litellm-backend-name-re
                        (gptel-backend-name gptel-backend))
    (let* ((info (gptel-fsm-info fsm))
           (session-id
            (with-current-buffer (plist-get info :buffer)
              gptel-litellm--session-id)))
      (when session-id
        (setq-local gptel--request-params
                    (gptel--merge-plists
                     gptel--request-params
                     (list :litellm_session session-id)))))))

(defun gptel-litellm-install-sessions ()
  "Add support for session-ids when using LiteLLM backends."
  (add-hook 'gptel-mode-hook #'gptel-litellm-set-session-id)
  (add-hook 'gptel-prompt-transform-functions
            #'gptel-litellm-add-litellm-session))

(provide 'gptel-litellm)

;;; gptel-litellm.el ends here
