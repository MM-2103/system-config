# -------------------------------------------------------------------
# ZSH
# -------------------------------------------------------------------
alias reload='source ~/.zshrc'

# -------------------------------------------------------------------
# Config
# -------------------------------------------------------------------
alias dotc="vim ~/dotfiles/"
alias sshc="vim ~/.ssh/config"
alias emacs='emacsclient --tty'
alias buuc='brew update && brew upgrade && brew cleanup'
alias bbd='brew bundle dump --describe -f'
t() {
  sesh connect "$(
    sesh list --icons | fzf-tmux -p 90%,90% \
      --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
      --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
      --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
      --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
      --preview-window 'right:60%' \
      --preview 'sesh preview {}'
  )"
}

alias jot='script -kadr $HOME/Documents/$(date "+%d-%m-%Y").txt'

# -------------------------------------------------------------------
# System
# -------------------------------------------------------------------
alias myip='wget http://ipinfo.io/ip -qO -'
alias size='du -sh * | sort -r -n | ack "[0-9][G|M]"'
alias ifa="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"
alias ifi="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: inactive'"
alias ifip="ifconfig | ack 'inet.*broadcast'"

# -------------------------------------------------------------------
# Misc alias
# -------------------------------------------------------------------
alias ytmp3="youtube-dl -x --audio-format mp3 $1"

# -------------------------------------------------------------------
# Custom OS alias
# -------------------------------------------------------------------
if [[ $OSTYPE == "linux-gnu" ]]; then
    # Custom Linux Aliases
elif [[ $OSTYPE == "darwin"* ]]; then
    # Custom MAC OSX Aliases
    alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/F$'
    alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Fi$'
fi
