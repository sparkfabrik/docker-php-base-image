#!/bin/sh

if [ -z "${1}" ]; then
  echo "You must provide the IP address of the PHP-FPM"
  exit 1
fi

if [ -z "${2}" ] || [ ${2} -le 0 ]; then
  echo "You must provide the PORT of the PHP-FPM"
  exit 2
fi

SCRIPT="/var/www/html/print_vars.php"
if [ -n "${3}" ]; then
  SCRIPT="${3}"
fi

SCRIPT_NAME=$(basename ${SCRIPT}) SCRIPT_FILENAME=${SCRIPT} REQUEST_METHOD=GET cgi-fcgi -bind -connect ${1}:${2}
