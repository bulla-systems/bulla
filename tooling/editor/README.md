# Editor support for Thermite

Thermite has no editor tooling upstream — `tooling/` holds gates and registries
and nothing that makes a `.th` file readable. These are Bulla's, offered for
upstream.

The surface highlighted is the proposed
[Thermite 3 one](../../docs/rfcs/surface-conventions.md): full-word clauses,
every clause a third-person-singular verb, the effect row on the arrow. The
Thermite 2 abbreviations are highlighted too, so a file written against either
surface reads correctly while a migration is in flight.

| file | for |
|---|---|
| `thermite.vim` | Vim and Neovim |
| `ftdetect-thermite.vim` | filetype detection for the above |
| `thermite.tmLanguage.json` | VS Code, Sublime, and anything TextMate-shaped |

## Vim

```sh
mkdir -p ~/.vim/syntax ~/.vim/ftdetect
cp thermite.vim          ~/.vim/syntax/thermite.vim
cp ftdetect-thermite.vim ~/.vim/ftdetect/thermite.vim
```

Needs `syntax on` and `filetype plugin indent on` in your `vimrc`. Neovim reads
`~/.config/nvim/` in place of `~/.vim/`.

## What it colours, and why that way

Clauses get `Statement`, the strongest group, because the clause vocabulary is
what the language is for. The effect row gets `PreProc` — it is type-level rather
than a predicate, so it should not read like one.

Parameterised effect atoms match only where they are applied, so `write(heap)`
in a row is an effect and a `write` elsewhere is an ordinary identifier.

## Checking it

[`docs/examples/thermite3-tour.th`](../../docs/examples/thermite3-tour.th)
exercises every construct in the proposed surface. It does not certify — the
syntax is proposed rather than shipped — and it is the right file to open when
changing a rule here.
