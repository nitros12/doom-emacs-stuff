;;; private/ben/config.el -*- lexical-binding: t; -*-

(setq ON-DESKTOP (string= (system-name) "home"))
(setq ON-LAPTOP (string= (system-name) "laptop"))

;; bindings
(map!
 (:leader
  (:prefix "f"
   :desc "Toggle Treemacs" "t" #'+treemacs/toggle-project)
  (:prefix "o"
   :desc "Open Shopping" "s" #'org-shopping-open
   :desc "Open kill ring" "k" #'+default/yank-pop
   :desc "Open notes.org" "n" #'org-notes-open))

 (:map evilem-map
  :after evil-easymotion
  "<down>" #'evilem-motion-next-line
  "<up>" #'evilem-motion-previous-line)

 (:map evil-window-map
  "<left>"     #'evil-window-left
  "<right>"    #'evil-window-right
  "<up>"       #'evil-window-up
  "<down>"     #'evil-window-down)

 ;; in lisp modes use default evil-delete for parinfer magic
 ;; (:mode (emacs-lisp-mode clojure-mode scheme-mode lisp-mode)
 ;;  :i "<backspace>" #'parinfer-backward-delete-char
 ;;  :i "C-d" #'delete-char)

 "<home>" #'back-to-indentation-or-beginning
 "<end>" #'end-of-line)

(use-package! engrave-faces-latex
  :after ox-latex)

(use-package! disable-mouse)
(use-package! github-review)
(use-package! github-browse-file)

(use-package! mermaid-mode
  :defer t
  :mode "\\.mmd$")

(use-package! geros
  :defer t
  :config
  (setq geros-eval-result-duration nil)
  :hook
  (geiser-mode . geros-mode))

(use-package! evil-lion
  :config
  (evil-lion-mode))

(use-package! sqlup-mode
  :defer t
  :commands (sqlup-mode)
  :hook ((sql-mode . sqlup-mode)
         (sql-interactive-mode . sqlup-mode)))

(use-package! backline
  :after outline
  :config (advice-add 'outline-flag-region :after 'backline-update))

(use-package! esh-autosuggest
  :defer t
  :hook (eshell-mode . esh-autosuggest-mode))

(after! lsp-haskell
  (require 'dash)
  (require 's)
  (require 'ht)

  ;; progress spams the minibuffer when we're viewing hovers, etc
  (setq lsp-haskell-server-path "haskell-language-server-wrapper"
        lsp-haskell-formatting-provider "fourmolu")

  ;; patch the result of haskell-language-server to select the first code fragment
  (cl-defmethod lsp-clients-extract-signature-on-hover (contents (_server-id (eql lsp-haskell)))
    (-let* (((&hash "value") contents)
            (groups (--partition-by (s-blank? it) (s-lines value)))
            (sig (--> groups
                   (--drop-while (not (s-equals? "```haskell" (car it))) it)
                   (car it)
                   (s-join "\n" it))))
      (lsp--render-element sig)))

  (setq-hook! 'haskell-mode-hook yas-indent-line 'fixed))

(use-package! org-ref
  :config
  (setq bibtex-completion-bibliography '("~/org/bibliography/references.bib")
        bibtex-completion-library-path '("~/org/research_stuff")
        bibtex-completion-notes-path "~/org/bibliography/notes.org"))

(use-package! el-patch)

(use-package! screenshot
  :commands (screenshot)
  :config/el-patch
  (defun screenshot--post-process (file)
    "Apply any image post-processing to FILE."
    (when (or (> screenshot-radius 0)
              (> screenshot-shadow-radius 0))
      (let ((result
             (shell-command-to-string
              (format (el-patch-concat "convert '%1$s' \\( +clone -alpha extract \\
\\( -size %2$dx%2$d xc:black -draw 'fill white circle %2$d,%2$d %2$d,0' -write mpr:arc +delete \\) \\
\\( mpr:arc \\) -gravity northwest -composite \\
\\( mpr:arc -flip \\) -gravity southwest -composite \\
\\( mpr:arc -flop \\) -gravity northeast -composite \\
\\( mpr:arc -rotate 180 \\) -gravity southeast -composite \\) \\
-alpha off -compose CopyOpacity -composite -compose over \\
\\( +clone -background '%3$s' -shadow %4$dx%5$d+%6$d+%7$d \\) \\
+swap -background none -layers merge "
                                       (el-patch-add "-matte -virtual-pixel transparent -distort barrel '0.04 0.0 0.0 0.9' ")
                                       "'%1$s'")
                      file
                      screenshot-radius
                      screenshot-shadow-color
                      screenshot-shadow-intensity
                      screenshot-shadow-radius
                      screenshot-shadow-offset-horizontal
                      screenshot-shadow-offset-vertical))))
        (unless (string= result "")
          (error "Could not apply imagemagick commands to image:\n%s" result))))
    (run-hook-with-args 'screenshot-post-process-hook file))
  :config
  (setq screenshot-shadow-color "rgba(0, 0, 0, 0.55)"
        screenshot-shadow-radius 20
        screenshot-shadow-intensity 50
        screenshot-shadow-offset-horizontal 0
        screenshot-shadow-offset-vertical 20
        screenshot-border-width 5))

;; (when ON-DESKTOP
;;   (use-package! mu4e-alert
;;     :config (mu4e-alert-set-default-style (if ON-LAPTOP 'notifier 'libnotify))
;;     :hook ((after-init . mu4e-alert-enable-notifications)
;;            (after-init . mu4e-alert-enable-mode-line-display)))

;;   (use-package! mu4e
;;     :config
;;     (setq mu4e-update-interval (* 60 5))
;;     (set-email-account! "gmail.com"
;;                         `((mu4e-sent-folder . "/gmail.com/Sent Mail")
;;                           (mu4e-drafts-folder . "/gmail.com/Drafts")
;;                           (mu4e-trash-folder . "/gmail.com/Bin")
;;                           (mu4e-refile-folder . "/gmai.com/All Mail")
;;                           (smtpmail-smtp-user . ,user-mail-address)))))

(when ON-DESKTOP
  (use-package! discord-emacs)
  (setq org-ditaa-jar-path "/usr/share/java/ditaa/ditaa-0_10.jar")
  (run-at-time "1 min" nil #'discord-emacs-run "384815451978334208"))

(after! lsp-mode
  (lsp-ui-mode +1)
  (setq lsp-flycheck-live-reporting +1
        lsp-lens-enable nil
        lsp-modeline-diagnostics-scope :project
        lsp-restart 'auto-restart
        lsp-enable-indentation t
        lsp-enable-file-watchers t
        lsp-headerline-breadcrumb-enable nil
        lsp-ui-doc-show-with-cursor nil)
  (dolist (dir '(
                 "[/\\\\]\\.venv"
                 "[/\\\\]\\.venv\\'"
                 "[/\\\\]assets\\'"))

    (push dir lsp-file-watch-ignored-directories))
  (add-to-list 'lsp-language-id-configuration '(cuda-mode . "ccls"))
  (add-to-list 'lsp-language-id-configuration '(p4lang-mode . "p4")))

(after! magit
  (magit-wip-mode 1))

(after! flycheck
  (add-hook! haskell-mode
    (add-to-list 'flycheck-disabled-checkers 'haskell-stack-ghc)
    (add-to-list 'flycheck-disabled-checkers 'haskell-ghc)
    (add-to-list 'flycheck-disabled-checkers 'haskell-hlint)))

(after! rustic
  (setq rustic-lsp-server 'rust-analyzer))

(after! lsp-rust
  (setq lsp-rust-analyzer-display-chaining-hints t
        lsp-rust-analyzer-display-parameter-hints t
        lsp-rust-analyzer-server-display-inlay-hints t
        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-diagnostics-enable-experimental t
        lsp-rust-analyzer-call-info-full t
        lsp-rust-analyzer-cargo-watch-command "clippy"))


(after! company
  (setq company-idle-delay 0.1)
  (add-hook! evil-normal-state-entry #'company-abort)
  (set-company-backend! '(text-mode
                          markdown-mode
                          gfm-mode)
    '(:seperate
      company-ispell
      company-files
      company-yasnippet)))

(add-hook! prog-mode #'rainbow-delimiters-mode)

(after! engrave-faces
  (setq engrave-faces-attributes-of-interest
        '(:foreground :slant :weight :height :strike-through)))

(after! ox-latex
  (setq org-latex-listings 'engraved)

  (setq org-latex-pdf-process
        '("%latex -interaction nonstopmode -output-directory %o %f"
          "biber %b"
          "%latex -interaction nonstopmode -output-directory %o %f"
          "%latex -interaction nonstopmode -output-directory %o %f")
        org-latex-reference-command "\\cref{%s}")

  (defadvice! org-latex-src-block-engraved (orig-fn src-block contents info)
    "Like `org-latex-src-block', but supporting an engraved backend"
    :around #'org-latex-src-block
    (if (eq 'engraved (plist-get info :latex-listings))
        (org-latex-scr-block--engraved src-block contents info)
      (funcall orig-fn src-block contents info)))

  (defadvice! org-latex-inline-src-block-engraved (orig-fn inline-src-block contents info)
    "Like `org-latex-inline-src-block', but supporting an engraved backend"
    :around #'org-latex-inline-src-block
    (if (eq 'engraved (plist-get info :latex-listings))
        (org-latex-inline-scr-block--engraved inline-src-block contents info)
      (funcall orig-fn src-block contents info)))

  (add-to-list 'org-latex-classes
               '("fancy-article"
                 "\\documentclass{scrartcl}\n
[DEFAULT-PACKAGES]
[PACKAGES]

\\usepackage[osf,largesc,helvratio=0.9]{newpxtext}
\\usepackage[scale=0.9]{sourcecodepro}

\\usepackage[activate={true,nocompatibility},final,tracking=true,kerning=true,spacing=true,factor=2000]{microtype}
\\usepackage[capitalize]{cleveref}

\\setlength{\\parskip}{\\baselineskip}
\\setlength{\\parindent}{0pt}

\\AtBeginEnvironment{quote}{\\itshape}
"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (defvar latex-fancy-hyperref "
\\colorlet{greenyblue}{blue!70!green}
\\colorlet{blueygreen}{blue!40!green}
\\providecolor{link}{named}{greenyblue}
\\providecolor{cite}{named}{blueygreen}
\\hypersetup{
  pdfauthor={%a},
  pdftitle={%t},
  pdfkeywords={%k},
  pdfsubject={%d},
  pdfcreator={%c},
  pdflang={%L},
  breaklinks=true,
  colorlinks=true,
  linkcolor=,
  urlcolor=link,
  citecolor=cite\n}
\\urlstyle{same}
")

  (defvar org-latex-universal-preamble "
\\usepackage[main,include]{embedall}
\\IfFileExists{./\\jobname.org}{\\embedfile[desc=The original file]{\\jobname.org}}{}
"
    "Preamble to be included in every export.")

  (defvar org-latex-caption-preamble "
\\usepackage{subcaption}
\\usepackage[hypcap=true]{caption}
\\setkomafont{caption}{\\sffamily\\small}
\\setkomafont{captionlabel}{\\upshape\\bfseries}
\\captionsetup{justification=raggedright,singlelinecheck=true}
\\setcapindent{0pt}
\\usepackage{capt-of} % required by Org
")

  (defvar org-latex-checkbox-preamble "
\\usepackage{pifont}
\\usepackage{amssymb} % for \square
\\newcommand{\\checkboxUnchecked}{$\\square$}
\\newcommand{\\checkboxTransitive}{\\rlap{\\raisebox{-0.1ex}{\\hspace{0.35ex}\\Large\\textbf -}}$\\square$}
\\newcommand{\\checkboxChecked}{\\rlap{\\raisebox{0.2ex}{\\hspace{0.35ex}\\scriptsize \\ding{52}}}$\\square$}
")

  (defvar org-latex-box-preamble "
% args = #1 Name, #2 Colour, #3 Ding, #4 Label
\\usepackage{pifont}
\\newcommand{\\defsimplebox}[4]{%
  \\definecolor{#1}{HTML}{#2}
  \\newenvironment{#1}
  {%
    \\par\\vspace{-0.7\\baselineskip}%
    \\textcolor{#1}{#3} \\textcolor{#1}{\\textbf{#4}}%
    \\vspace{-0.8\\baselineskip}
    \\begin{addmargin}[1em]{1em}
  }{%
    \\end{addmargin}
    \\vspace{-0.5\\baselineskip}
  }%
}
\\defsimplebox{warning}{e66100}{\\ding{68}}{Warning}
\\defsimplebox{info}{3584e4}{\\ding{68}}{Information}
\\defsimplebox{success}{26a269}{\\ding{68}}{\\vspace{-\\baselineskip}}
\\defsimplebox{error}{c01c28}{\\ding{68}}{Important}
")

  (setq org-latex-default-class "fancy-article"
        org-latex-tables-booktabs t
        org-latex-hyperref-template latex-fancy-hyperref)

  (defun org-babel-tangle-files ()
    "All files that may be tangled to.
Uses a stripped-down version of `org-babel-tangle'"
    (let (files)
      (save-excursion
        (mapc ;; map over all languages
         (lambda (by-lang)
           (let* ((lang (car by-lang))
                  (specs (cdr by-lang))
                  (ext (or (cdr (assoc lang org-babel-tangle-lang-exts)) lang)))
             (mapc
              (lambda (spec)
                (let ((get-spec (lambda (name) (cdr (assoc name (nth 4 spec))))))
                  (let* ((tangle (funcall get-spec :tangle))
                         (base-name (cond
                                     ((string= "yes" tangle)
                                      (file-name-sans-extension
                                       (nth 1 spec)))
                                     ((string= "no" tangle) nil)
                                     ((> (length tangle) 0) tangle)))
                         (file-name (when base-name
                                      ;; decide if we want to add ext to base-name
                                      (if (and ext (string= "yes" tangle))
                                          (concat base-name "." ext) base-name))))
                    (push file-name files))))
              specs)))
         (org-babel-tangle-collect-blocks)))
      (delq nil (cl-delete-duplicates files :test #'string=))))

  (defun org-latex-embed-tangled-files ()
    "Return a string that uses embedfile to embed all tangled files."
    (mapconcat
     (lambda (tangle-file)
       (format "\\IfFileExists{%1$s}{\\embedfile[desc=A tangled file]{%1$s}}{}"
               (->> tangle-file
                 (replace-regexp-in-string "\\\\" "\\\\\\\\")
                 (replace-regexp-in-string "~" "\\\\string~"))))
     (org-babel-tangle-files)
     "\n"))

  (defvar org-latex-conditional-preambles
    '((t . org-latex-universal-preamble)
      ("^[\t ]*#\\+begin_src" . org-latex-embed-tangled-files)
      ("\\[\\[file:\\(?:[^\\]]+?|\\\\\\]\\)\\.svg\\]\\]" . "\\usepackage{svg}")
      ("\\[\\[file:\\(?:[^]]\\|\\\\\\]\\)+\\.\\(?:eps\\|pdf\\|png\\|jpeg\\|jpg\\|jbig2\\)\\]\\]" . "\\usepackage{graphicx}")
      ("^[      ]*|" . "\\usepackage{longtable}\n\\usepackage{booktabs}")
      ;; ("\\\\(\\|\\\\\\[\\|\\\\begin{\\(?:math\\|displaymath\\|equation\\|align\\|flalign\\|multiline\\|gather\\)[a-z]*\\*?}"
      ;;  . "\\usepackage{bmc-maths}")
      ;; ("\\+[^ ].*[^ ]\\+\\|_[^ ].*[^ ]_\\|\\\\uu?line\\|\\\\uwave\\|\\\\sout\\|\\\\xout\\|\\\\dashuline\\|\\dotuline\\|\\markoverwith"
      ;;  . "\\usepackage[normalem]{ulem}")
      (":float wrap" . "\\usepackage{wrapfig}")
      (":float sideways" . "\\usepackage{rotating}")
      ("^[\t ]*#\\+caption:\\|\\\\caption" . org-latex-caption-preamble)
      ("^[\t ]*\\(?:[-+*]\\|[0-9]+[.)]\\|[A-Za-z]+[.)]\\) \\[[ -X]\\]" . org-latex-checkbox-preamble)
      ("^[\t ]*#\\+begin_\\(?:warning\\|info\\|success\\|error\\)\\|\\\\begin{\\(?:warning\\|info\\|success\\|error\\)}"
       . org-latex-box-preamble))
    "Snippets which are conditionally included in the preamble of a LaTeX export.

Alist where when the car results in a non-nil value, the cdr is inserted in
the preamble.  The car may be a:
- string, which is used as a regex search in the buffer
- symbol, the value of which used
- function, the result of the function is used

The cdr may be a:
- string, which is inserted without processing
- symbol, the value of which is inserted
- function, the result of which is inserted")

  (defadvice! org-latex-header-smart-preamble (orig-fn tpl def-pkg pkg snippets-p &optional extra)
    "Dynamically insert preamble content based on `org-latex-conditional-preambles'."
    :around #'org-splice-latex-header
    (let ((header (funcall orig-fn tpl def-pkg pkg snippets-p extra)))
      (if snippets-p header
        (concat header
                (mapconcat (lambda (term-preamble)
                             (when (pcase (car term-preamble)
                                     ((pred stringp) (save-excursion
                                                       (goto-char (point-min))
                                                       (search-forward-regexp (car term-preamble) nil t)))
                                     ((pred functionp) (funcall (car term-preamble)))
                                     ((pred symbolp) (symbol-value (car term-preamble)))
                                     (_ (user-error "org-latex-conditional-preambles key %s unable to be used" (car term-preamble))))
                               (concat
                                (pcase (cdr term-preamble)
                                  ((pred stringp) (cdr term-preamble))
                                  ((pred functionp) (funcall (cdr term-preamble)))
                                  ((pred symbolp) (symbol-value (cdr term-preamble)))
                                  (_ (user-error "org-latex-conditional-preambles value %s unable to be used" (cdr term-preamble))))
                                "\n")))
                           org-latex-conditional-preambles
                           "") "\n"))))

  (setq org-latex-engraved-code-preamble "
\\usepackage{fvextra}
\\fvset{
  commandchars=\\\\\\{\\},
  highlightcolor=white!95!black!80!blue,
  breaklines=true,
  breaksymbol=\\color{white!60!black}\\tiny\\ensuremath{\\hookrightarrow}}
\\renewcommand\\theFancyVerbLine{\\footnotesize\\color{black!40!white}\\arabic{FancyVerbLine}}

% TODO have code boxes keep line vertical alignment
\\usepackage[breakable,xparse]{tcolorbox}
\\DeclareTColorBox[]{Code}{o}%
{colback=white!97!black, colframe=white!94!black,
  fontupper=\\color{EFD}\\footnotesize,
  IfNoValueTF={#1}%
  {boxsep=2pt, arc=2.5pt, outer arc=2.5pt,
    boxrule=0.5pt, left=2pt}%
  {boxsep=2.5pt, arc=0pt, outer arc=0pt,
    boxrule=0pt, leftrule=1.5pt, left=0.5pt},
  right=2pt, top=1pt, bottom=0.5pt,
  breakable}
")

  (add-to-list 'org-latex-conditional-preambles '("^[\t ]*#\\+BEGIN_SRC\\|#\\+begin_src" . org-latex-engraved-code-preamble) t)
  (add-to-list 'org-latex-conditional-preambles '("^[\t ]*#\\+BEGIN_SRC\\|#\\+begin_src" . engrave-faces-latex-gen-preamble) t)

  (defun org-latex--caption/label-string (element info)
    "Return caption and label LaTeX string for ELEMENT.

INFO is a plist holding contextual information.  If there's no
caption nor label, return the empty string.

For non-floats, see `org-latex--wrap-label'."
    (let* ((label (org-latex--label element info nil t))
           (main (org-export-get-caption element))
           (attr (org-export-read-attribute :attr_latex element))
           (type (org-element-type element))
           (nonfloat t)
           (short (org-export-get-caption element t))
           (caption-from-attr-latex (plist-get attr :caption)))
      (cond
       ((org-string-nw-p caption-from-attr-latex)
        (concat caption-from-attr-latex "\n"))
       ((and (not main) (equal label "")) "")
       ((not main) label)
       ;; Option caption format with short name.
       (t
        (format (if nonfloat "\\captionof{%s}%s{%s}\n%s"
                  "\\caption%s%s{%s}\n%s")
                (let ((type* (if (eq type 'latex-environment)
                                 (org-latex--environment-type element)
                               type)))
                  (if nonfloat
                      (cl-case type*
                        (paragraph "figure")
                        (image "figure")
                        (special-block "figure")
                        (src-block (if (plist-get info :latex-listings)
                                       "listing"
                                     "figure"))
                        (t (symbol-name type*)))
                    ""))
                (if short (format "[%s]" (org-export-data short info)) "")
                (org-export-data main info)
                label)))))

  (defun org-latex-scr-block--engraved (src-block contents info)
    (let* ((lang (org-element-property :language src-block))
           (attributes (org-export-read-attribute :attr_latex src-block))
           (float (plist-get attributes :float))
           (num-start (org-export-get-loc src-block info))
           (retain-labels (org-element-property :retain-labels src-block))
           (caption (org-element-property :caption src-block))
           (caption-above-p (org-latex--caption-above-p src-block info))
           (caption-str (org-latex--caption/label-string src-block info))
           (placement (or (org-unbracket-string "[" "]" (plist-get attributes :placement))
                          (plist-get info :latex-default-figure-position)))
           (float-env
            (cond
             ((string= "multicolumn" float)
              (format "\\begingroup\n%s%%s\n%s\\endgroup"
                      (if caption-above-p caption-str "")
                      (if caption-above-p "" caption-str)))
             (caption
              (format "\\begingroup\n%s%%s\n%s\\endgroup"
                      (if caption-above-p caption-str "")
                      (if caption-above-p "" caption-str)))
             ((string= "t" float)
              "\\begingroup\n%s\n\\endgroup")
             (t "%s")))
           (options (plist-get info :latex-minted-options))
           (content-buffer
            (with-temp-buffer
              (insert
               (let* ((code-info (org-export-unravel-code src-block))
                      (max-width
                       (apply 'max
                              (mapcar 'length
                                      (org-split-string (car code-info)
                                                        "\n")))))
                 (org-export-format-code
                  (car code-info)
                  (lambda (loc _num ref)
                    (concat
                     loc
                     (when ref
                       ;; Ensure references are flushed to the right,
                       ;; separated with 6 spaces from the widest line
                       ;; of code.
                       (concat (make-string (+ (- max-width (length loc)) 6)
                                            ?\s)
                               (format "(%s)" ref)))))
                  nil (and retain-labels (cdr code-info)))))
              (funcall (org-src-get-lang-mode lang))
              (engrave-faces-latex-buffer)))
           (content
            (with-current-buffer content-buffer
              (buffer-string)))
           (body
            (format
             "\\begin{Code}\n\\begin{Verbatim}[%s]\n%s\\end{Verbatim}\n\\end{Code}"
             ;; Options.
             (concat
              (org-latex--make-option-string
               (if (or (not num-start) (assoc "linenos" options))
                   options
                 (append
                  `(("linenos")
                    ("firstnumber" ,(number-to-string (1+ num-start))))
                  options)))
              (let ((local-options (plist-get attributes :options)))
                (and local-options (concat "," local-options))))
             content)))
      (kill-buffer content-buffer)
      ;; Return value.
      (format float-env body)))

  (defun org-latex-inline-scr-block--engraved (inline-src-block _contents info)
    (let ((options (org-latex--make-option-string
                    (plist-get info :latex-minted-options)))
          code-buffer code)
      (setq code-buffer
            (with-temp-buffer
              (insert (org-element-property :value inline-src-block))
              (funcall (org-src-get-lang-mode
                        (org-element-property :language inline-src-block)))
              (engrave-faces-latex-buffer)))
      (setq code (with-current-buffer code-buffer
                   (buffer-string)))
      (kill-buffer code-buffer)
      (format "\\Verb%s{%s}"
              (if (string= options "") ""
                (format "[%s]" options))
              code)))
  (defadvice! org-latex-example-block-engraved (orig-fn example-block contents info)
    "Like `org-latex-example-block', but supporting an engraved backend"
    :around #'org-latex-example-block
    (let ((output-block (funcall orig-fn example-block contents info)))
      (if (eq 'engraved (plist-get info :latex-listings))
          (format "\\begin{Code}[alt]\n%s\n\\end{Code}" output-block)
        output-block))))

(after! org
  (setq org-tags-column 100
        org-sticky-header-full-path 'full)

  (add-hook! org-mode
    (org-sticky-header-mode 1))

  (add-to-list 'org-src-lang-modes
               '("p4" . p4lang))

  (setq org-attach-screenshot-command-line "escrotum -s %f")
  (setq org-catch-invisible-edits 'show-and-error
        org-cycle-separator-lines 0)

  (setq org-log-done 'time
        +org-default-notes-file (f-join org-directory "notes.org")
        +org-default-todo-file (f-join org-directory "todo.org")
        +org-default-calendar-file (f-join org-directory "calendar.org")
        +org-shopping-file (f-join org-directory "shopping_list.org"))

  (setq org-capture-templates
        '(("t" "Todo" entry (file +org-default-todo-file)
           "* [ ] %?\n%i" :prepend t :kill-buffer t)
          ("n" "Notes" entry (file +org-default-notes-file)
           "* %u %?\n%i" :prepend t :kill-buffer t)
          ("c" "Calendar" entry (file +org-default-calendar-file)
           "* %?\n%^T")
          ("h" "Hugo post" entry (file+olp "blog.org" "Blog")
           (function org-hugo-new-subtree-post-capture-template))
          ("s" "Shopping" plain (file +org-shopping-file)
           (function org-shopping-goto-last-open-or-make-new))))


  (setq org-agenda-files (list +org-default-todo-file
                               +org-default-calendar-file
                               (f-join org-directory "lectures.org"))))

(setq frame-title-format (list "%b - " (user-login-name) "@" (system-name)))

(when ON-LAPTOP
  (after! disable-mouse
    (global-disable-mouse-mode)))

(after! haskell-mode
  (setq haskell-auto-insert-module-format-string "-- | \nmodule %s\n    (\n     ) where"))

(after! evil
  (setq evil-normal-state-cursor '(box "light blue")
        evil-insert-state-cursor '(bar "medium sea green")
        evil-visual-state-cursor '(hollow "orange")
        evil-want-fine-undo t)
  (setq evil-vsplit-window-right t
        evil-split-window-below t)
  ;; stops the evil selection being added to the kill-ring
  (fset 'evil-visual-update-x-selection 'ignore)
  (defadvice! prompt-for-buffer (&rest _)
    :after '(evil-window-split evil-window-vsplit)
    (consult-buffer))
  (advice-add 'evil-ex-search-next :after
              (lambda (&rest _x) (evil-scroll-line-to-center (line-number-at-pos))))
  (advice-add 'evil-ex-search-previous :after
              (lambda (&rest _x) (evil-scroll-line-to-center (line-number-at-pos)))))

(after! consult
  (setq consult-async-refresh-delay 0.1
        consult-async-input-throttle 0.1
        consult-async-refresh-delay 0.1))

(after! ivy
  (add-to-list 'ivy-re-builders-alist `(counsel-find-file . ,#'+ivy-prescient-non-fuzzy))
  (add-to-list 'ivy-re-builders-alist `(counsel-file-jump . ,#'+ivy-prescient-non-fuzzy))
  (add-to-list 'ivy-re-builders-alist `(counsel-projectile-find-file . ,#'+ivy-prescient-non-fuzzy)))

(after! ispell
  (setq ispell-dictionary "english"))

(setq-default x-stretch-cursor t
              uniquify-buffer-name-style 'forward)

(setq projectile-require-project-root t)

(setq posframe-mouse-banish nil)

(setq display-line-numbers-type nil)

(global-subword-mode 1)

(set-popup-rule! "^\\* Racket REPL"
  :side 'right
  :quit nil
  :size 0.35)

(set-popup-rule! "^\\*Man"
  :side 'right
  :size 0.35)

;; mhtml mode pls
(add-to-list 'auto-mode-alist '("\\.eex$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.j2$" . web-mode))

(setq +treemacs-git-mode 'deferred)

(after! treemacs
  (treemacs-follow-mode +1)
  (setq treemacs-silent-refresh t
        doom-themes-treemacs-theme "Default"
        doom-themes-treemacs-bitmap-indicator-width 7))

;; (add-hook 'after-make-frame-functions
;;           (lambda (_)
;;             (run-at-time "1 sec" nil #'doom/reload-theme)))

(setq deft-directory "~/org/lectures"
      deft-recursive t)

;; yeet
(set-formatter! 'fourmolu "fourmolu" :modes '(haskell-mode))

(setq safe-local-variable-values '((ssh-deploy-async . 1)))

(add-hook! cuda-mode
  (yas-minor-mode-on))

(set-irc-server! "irc.libera.chat"
                 `(:tls t
                   :port 6697
                   :nick "simmsb"
                   :user "simmsb"
                   :realname "Ben Simms"
                   :sasl-username "simmsb"
                   :sasl-password (lambda (&rest _) (+pass-get-secret "libera/password"))
                   :channels (:after-auth "#haskell" "#haskell-in-depth")))

(after! circe
  (enable-circe-color-nicks)
  (enable-circe-notifications)
  (enable-circe-display-images)
  (circe-lagmon-mode +1)
  (setq lui-logging-directory "~/.irc-logs")
  (enable-lui-logging-globally))

(after! forge
  (if (atom forge-topic-list-limit)
      (setq forge-topic-list-limit (cons forge-topic-list-limit -5))
    (setcdr forge-topic-list-limit -5)))

(defun cc-bytecomp-is-compiling (&rest _))

(after! counsel
  (setq counsel-rg-base-command "rg -M 240 --with-filename --no-heading --line-number --color never %s 2>/dev/null || true"))

(after! geiser
  (setq geiser-scheme-implementation 'guile
        geiser-active-implementations '(guile)))

(pcase (system-name)
  ("home"
   (setq doom-theme 'doom-horizon))
  ("laptop"
   (toggle-frame-maximized)
   (setq doom-theme 'doom-tomorrow-night))
  ("work-desktop"
   (setq doom-theme 'doom-wilmersdorf)))
