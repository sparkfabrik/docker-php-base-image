#!/bin/sh

set -e

find . -type f \
  '(' \
    -name '*.bash' \
    -o -name '.bashrc' \
    -o -name 'bashrc' \
    -o -name '.bash_aliases' \
    -o -name '.bash_completion' \
    -o -name '.bash_login' \
    -o -name '.bash_logout' \
    -o -name '.bash_profile' \
    -o -name 'bash_profile' \
    -o -name '*.ksh' \
    -o -name 'suid_profile' \
    -o -name '*.zsh' \
    -o -name '.zlogin' \
    -o -name 'zlogin' \
    -o -name '.zlogout' \
    -o -name 'zlogout' \
    -o -name '.zprofile' \
    -o -name 'zprofile' \
    -o -name '.zsenv' \
    -o -name 'zsenv' \
    -o -name '.zshrc' \
    -o -name 'zshrc' \
    -o -name '*.sh' \
    -o -path '*/.profile' \
    -o -path '*/profile' \
    -o -name '*.shlib' \
  ')' -exec shellcheck {} \;
