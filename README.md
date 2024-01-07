# ocaml-ts-mode

Ocaml mode for emacs using treesitter.

This is beta software and in development.

It implements:


- Syntax highlighting for `.ml` and `.mli` files.
- Rudimentary indentation.
- `C-c C-a` - Switch between `.ml` and `.mli` files for a module.

## How to Install

You will need a version of Emacs with treesitter enabled.

1. Setup the source list for the ocaml treesitter grammar.  Add the following to
   your `~/.emacs`:
   ```elisp
   (setq treesit-language-source-alist
      '((ocaml "https://github.com/tree-sitter/tree-sitter-ocaml" "master" "ocaml/src")))
   ```
2. Install the treesitter grammar: `M-x treesit-install-language-grammar RET ocaml RET`.
3. Clone this repository.
4. Add a progmode directory to your emacs path.  For this step, there are
   several ways to accomplish this, these directions show one way to do it.  The
   goal is for emacs to see the `ocaml-ts-mode.el` file.  To do this I have a
   directory called `~/.emacs-progmode` and then I add that path to emacs by
   adding the following line to my `~/.emacs`: `(add-to-list 'load-path
   "~/.emacs-progmode")`.
5. Symlink `ocaml-ts-mode.el` into the progmode directory.  Given the step
   above, that would be `~/.emacs-progmode/`.
6. Add `ocaml-ts-mode` to autoload:
   ```elisp
   (autoload 'ocaml-ts-mode "ocaml-ts-mode" "Major mode for editing Ocaml code" t)
   ```
7. Optional: By default, `ocaml-ts-mode` sets itself up for `.ml` and `.mli`
   files.  However if you are using another ocaml mode, such as Tuareg or
   camlmode, you will need to either manually switch to `ocaml-ts-mode` by doing
   `M-x ocaml-ts-mode RET` or by remapping the major mode, for example by adding
   the following to `~/.emacs`:
   ```elisp
   (setq major-mode-remap-alist
      '((tuareg-mode . ocaml-ts-mode)))
   ```

Finally, you can configure `ocaml-ts-mode` when it load via a hook.  For example:

```elisp
(add-hook 'ocaml-ts-mode-hook
          (lambda ()
            (eglot-ensure)
            (company-mode)
            (flyspell-prog-mode)
            (local-set-key (kbd "C-<tab>") 'company-complete)
            (add-hook 'before-save-hook 'ocamlformat)
            (setq indent-tabs-mode nil)
            (setq truncate-lines t)
            (setq whitespace-line-column 100)
            (setq whitespace-style '(face trailing lines-tail))
            (whitespace-mode)
            (yafolding-mode)
            (rainbow-delimiters-mode)))
```

## Comparison to Tuareg mode

`ocaml-ts-mode` is a new project and currently only supports `.ml` and `.mli`
files.  It is also much less feature rich then Tuareg mode.

Treesitter is considered the future of programming major modes in Emacs.  The
power of it is treesitter understands the syntax of a language and thus the
syntax highlighting can be more precise.  For example, `ocaml-ts-mode`
highlights function calls different than field access.  It also has good support
for multiple languages in a single buffer.

![Screenshot](ss.png?raw=true "Screenshot")

## Future Work & Ways to Contribute

`ocaml-ts-mode` does not have many features and is beta.

To contribute, just open a pull request!

Some known work that needs to be done:

1. Improve indentation support.
2. Make sure the syntax grammar covers all cases.
3. Figure out if the ocaml interface treesitter grammar should be used, and how.
   Currently just the ocaml grammar is used.
4. Add more useful features.

## Useful links

- How to get started with tree sitter -
  https://www.masteringemacs.org/article/how-to-get-started-tree-sitter
- Tree Sitter and the Complications of Parsing Languages -
  https://www.masteringemacs.org/article/tree-sitter-complications-of-parsing-languages
- Let's write a treesitter major mode -
  https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode
