# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Set up SSH auth with gpg-agent and set correct tty
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >> /dev/null

# Miscellaneous
export SYSTEMD_PAGER=
