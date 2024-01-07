;;; ocaml-ts-mode.el --- tree-sitter support for Ocaml  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Terrateam B.V.

;; Author     : Malcolm Matalka <malcolm@terrateam.io>
;; Maintainer : Malcolm Matalka <malcolm@terrateam.io>
;; Created    : January 2024
;; Keywords   : ocaml languages tree-sitter

;;; Commentary:
;;

;;; Code:

(require 'treesit)
(require 'find-file)

(defcustom ocaml-ts-mode-other-file-alist
  '(("\\.mli\\'" (".ml"))
    ("\\.ml\\'" (".mli")))
  "Associative list of alternate extensions to find.
See `ff-other-file-alist'."
  :group 'ocaml
  :type '(repeat (list regexp (choice (repeat string) function))))

(defvar ocaml-ts-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-a") #'ff-get-other-file)
    map)
  "Keymap used in `ocaml-ts-mode'.")

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")

(defcustom ocaml-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `ocaml-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'ocaml)


(defvar ocaml-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?# "." table)
    (modify-syntax-entry ?? ". p" table)
    (modify-syntax-entry ?~ ". p" table)
    (dolist (c '(?! ?$ ?% ?& ?+ ?- ?/ ?: ?< ?= ?> ?@ ?^ ?|))
      (modify-syntax-entry c "." table))
    (modify-syntax-entry ?' "_" table) ; ' is part of symbols (for primes).
    (modify-syntax-entry ?\" "\"" table) ; " is a string delimiter
    (modify-syntax-entry ?\\ "\\" table)
    (modify-syntax-entry ?*  ". 23" table)
    (modify-syntax-entry ?\( "()1n" table)
    (modify-syntax-entry ?\) ")(4n" table)
    table)
  "Syntax table for `ocaml-ts-mode'.")

(defvar ocaml-ts--indent-rules
  `((ocaml
     ((parent-is "compilation_unit") column-0 0)
     ((node-is "sig") parent-bol ocaml-ts-mode-indent-offset)
     ((node-is "struct") parent-bol ocaml-ts-mode-indent-offset)
     ((parent-is "let_binding") parent-bol ocaml-ts-mode-indent-offset)
     ((node-is "in") parent-bol 0)
     ((node-is "end") parent-bol 0)
     ((parent-is "->") parent-bol ocaml-ts-mode-indent-offset)
     ))
  )

(defvar ocaml-ts-mode--keywords
  '(
    "and"
    "begin"
    "class"
    "do"
    "done"
    "downto"
    "else"
    "end"
    "for"
    "fun"
    "function"
    "functor"
    "if"
    "in"
    "include"
    "let"
    "match"
    "module"
    "mutable"
    "object"
    "of"
    "open"
    "rec"
    "sig"
    "struct"
    "then"
    "to"
    "type"
    "val"
    "when"
    "while"
    "with"
    )
  "Ocaml keywords for tree-sitter font-locking.")

(defvar ocaml-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'ocaml
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'ocaml
   :feature 'constant
   '((constructor_name) @font-lock-constant-face
     (module_name) @font-lock-type-face
     (tag) @font-lock-constant-face
     (boolean) @font-lock-constant-face)

   :language 'ocaml
   :feature 'bracket
   '((["(" ")" "[" "]" "{" "}"]) @font-lock-bracket-face)

   :language 'ocaml
   :feature 'delimiter
   '((["," "." ";" ":" ";;"]) @font-lock-delimiter-face)

   :language 'ocaml
   :feature 'keyword
   `([,@ocaml-ts-mode--keywords] @font-lock-keyword-face)

   :language 'ocaml
   :feature 'definition
   '((let_binding pattern: (value_name) @font-lock-function-name-face))

   :language 'ocaml
   :feature 'variable
   '((value_name) @font-lock-variable-use-face
     (field_name) @font-lock-variable-use-face)

   :language 'ocaml
   :feature 'ppx
   '((attribute_id) @font-lock-function-call-face)

   :language 'ocaml
   :feature 'function
   :override t
   '((application_expression function: (value_path (value_name) @font-lock-function-call-face))
     (application_expression function: (value_path (module_path (_) @font-lock-type-face) (value_name) @font-lock-function-call-face)))

   :language 'ocaml
   :feature 'number
   '((number) @font-lock-number-face)

   :language 'ocaml
   :feature 'string
   '((string) @font-lock-string-face
     (character) @font-lock-string-face)

   :language 'ocaml
   :feature 'escape-sequence
   :override t
   '((escape_sequence) @font-lock-escape-face)

   :language 'ocaml
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Font-lock settings for Ocaml.")

;; (defun ocaml-ts-mode--defun-name (node)
;;   "Return the defun name of NODE.
;; Return nil if there is no name or if NODE is not a defun node."
;;   (pcase (treesit-node-type node)
;;     ((or "pair" "object")
;;      (string-trim (treesit-node-text
;;                    (treesit-node-child-by-field-name
;;                     node "key")
;;                    t)
;;                   "\"" "\""))))

;;;###autoload
(define-derived-mode ocaml-ts-mode prog-mode "Ocaml"
  "Major mode for editing Ocaml, powered by tree-sitter."
  :group 'ocaml
  :syntax-table ocaml-ts-mode--syntax-table

  (unless (treesit-ready-p 'ocaml)
    (error "Tree-sitter for OCAML isn't available"))

  (treesit-parser-create 'ocaml)

  ;; Indent.
  (setq-local treesit-simple-indent-rules ocaml-ts--indent-rules)


  ;; Font-lock.
  (setq-local treesit-font-lock-settings ocaml-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
              '((comment number string)
                (keyword constant)
                (escape-sequence function variable definition ppx)
                (bracket delimiter error)))

  (setq ff-search-directories '(".")
        ff-other-file-alist ocaml-ts-mode-other-file-alist)

  (treesit-major-mode-setup))

(if (treesit-ready-p 'ocaml)
    (add-to-list 'auto-mode-alist
                 '("\\.mli?\\'" . ocaml-ts-mode)))

(provide 'ocaml-ts-mode)

;;; ocaml-ts-mode.el ends here
