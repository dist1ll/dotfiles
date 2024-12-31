# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export XCC=/usr/bin/clang
export XCXX=/usr/bin/clang++ 
export XCPP=/usr/bin/clang-cpp
export XLD=/usr/bin/ld.lld

export EDITOR=hx
export PATH=$PATH:~/bin
export PATH=$PATH:~/.local/bin

# Set up SSH auth with gpg-agent and set correct tty
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >> /dev/null

# Miscellaneous
export SYSTEMD_PAGER=
. "$HOME/.cargo/env"
