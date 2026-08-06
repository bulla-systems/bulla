" Vim syntax file for Thermite 3
" Language:    Thermite (.th)
" Maintainer:  Bulla — docs/rfcs/surface-conventions.md
"
" The surface this highlights is the proposed Thermite 3 one: full-word clauses,
" every clause a third-person-singular verb, the effect row on the arrow. It also
" keeps the current Thermite 2 abbreviations highlighted, so a file written
" against either surface reads correctly while the migration is in flight.

if exists("b:current_syntax")
  finish
endif

syn case match

" --- items and modifiers -----------------------------------------------------
syn keyword thermiteItem      fn struct enum protocol effect operation law
syn keyword thermiteItem      shared lock handlers
syn keyword thermiteSpecKw    spec
syn keyword thermiteModifier  opaque resource pub

" --- clauses: the vocabulary this language is about --------------------------
syn keyword thermiteClause    requires ensures survives measures keeps
syn keyword thermiteClause    asks promises
" Thermite 2 spellings, kept so migrating files still read
syn keyword thermiteClauseOld req ens inv dec fx

" --- blocks that head a scope ------------------------------------------------
syn keyword thermiteBlockKw   interleaves holding picks

" --- declaration connectives -------------------------------------------------
syn keyword thermiteConnect   guards after at end repeat

" --- effect atoms ------------------------------------------------------------
" bare atoms — distinctive enough to match anywhere
syn keyword thermiteEffect    pure panic diverge blocks random
syn keyword thermiteEffect    alloc time rand term irq masked
" parameterised atoms — only where they are applied, so `write` as an ordinary
" identifier elsewhere is left alone
syn match   thermiteEffect    "\<\%(read\|write\|owns\|forgets\|accrues\|cost\|net\|platform\|state\|io\|exception\|partiality\)\ze("

" the effect row marker
syn match   thermiteRowMark   "^\s*!"

" --- statements and expressions ----------------------------------------------
syn keyword thermiteStmt      let mut return break continue
syn keyword thermiteCond      if else match loop while
syn keyword thermiteOperator  as is forall exists
syn keyword thermiteHint      by unfold
syn keyword thermiteTrivial   nothing

" --- special names -----------------------------------------------------------
syn keyword thermiteSpecial   result final self forget
syn keyword thermiteBoolean   true false

" --- types -------------------------------------------------------------------
syn keyword thermiteType      u8 u16 u32 u64 usize i8 i16 i32 i64 isize
syn keyword thermiteType      bool char nat int
syn keyword thermiteType      Vec Map Set Multiset Seq Result Option String Box
" a capitalised identifier is a declared type — or a protocol role, which is one
syn match   thermiteUserType  "\<\u\w*\>"
" a path into a protocol: PageRequest::Provider
syn match   thermitePath      "\<\u\w*::\u\w*\>"

" --- literals and punctuation ------------------------------------------------
syn match   thermiteNumber    "\<\d\+\%(_\d\+\)*\>"
syn match   thermiteNumber    "\<0x\x\+\>"
syn region  thermiteString    start=+"+ skip=+\\.+ end=+"+ contains=thermiteEscape
syn match   thermiteEscape    "\\." contained
syn match   thermiteOperator  "[-+*/%!<>=&|^]"
syn match   thermiteOperator  "->\|=>\|::\|=="
syn match   thermiteDelim     "[(){}\[\],;]"
syn match   thermiteIdent     "\<\l\w*\>" contained

" --- attributes and comments -------------------------------------------------
syn match   thermiteAttribute "#\[[^]]*\]"
syn region  thermiteComment   start="//" end="$" contains=thermiteTodo,@Spell
syn region  thermiteComment   start="/\*" end="\*/" contains=thermiteTodo,@Spell
syn keyword thermiteTodo      TODO FIXME NOTE SHIPPED contained

" --- highlight links ---------------------------------------------------------
" Clauses are the point of the language, so they get the strongest group.
hi def link thermiteClause     Statement
hi def link thermiteClauseOld  Statement
hi def link thermiteTrivial    Statement

hi def link thermiteItem       Keyword
hi def link thermiteSpecKw     Keyword
hi def link thermiteBlockKw    Keyword
hi def link thermiteStmt       Keyword
hi def link thermiteCond       Conditional
hi def link thermiteModifier   StorageClass
hi def link thermiteConnect    Keyword

" The row is type-level, so it reads as a type rather than as a predicate.
hi def link thermiteRowMark    PreProc
hi def link thermiteEffect     PreProc

hi def link thermiteHint       Special
hi def link thermiteSpecial    Constant
hi def link thermiteBoolean    Boolean
hi def link thermiteType       Type
hi def link thermiteUserType   Type
hi def link thermitePath       Type
hi def link thermiteNumber     Number
hi def link thermiteString     String
hi def link thermiteEscape     SpecialChar
hi def link thermiteOperator   Operator
hi def link thermiteDelim      Delimiter
hi def link thermiteAttribute  PreProc
hi def link thermiteComment    Comment
hi def link thermiteTodo       Todo

let b:current_syntax = "thermite"
