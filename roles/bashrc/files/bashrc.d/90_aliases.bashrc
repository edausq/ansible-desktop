# User specific aliases and functions
alias l='ls -l'
alias ll='ls -la'

# confirm overide
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# auto ssh-add
alias ssh='ssh-add -l >/dev/null || ssh-add; ssh'
