# Linux shims so mac-isms (pbcopy/open) keep working
if [[ "$OSTYPE" == linux* ]]; then
    pbcopy() { xclip -selection clipboard; }
    pbpaste() { xclip -selection clipboard -o; }
    open() { xdg-open "$@" >/dev/null 2>&1; }
fi

alias o='open .'
alias pc='pwd | pbcopy'
