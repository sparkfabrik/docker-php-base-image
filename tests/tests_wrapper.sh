#!/bin/sh

# Simply wraps the calls to image_verify
# Arguments are:
# 1: subfolder for expectations (php7)
# 2: php image to test
# 3: user (optional)

BASE=$(dirname "${0}")

if [ -n "${1}" ] && [ -d "${BASE}/expectations/${1}" ] && [ -n "${2}" ]; then
  USER="root"
  if [ -n "${3}" ]; then
    USER="${3}"
  fi

  "${BASE}"/image_verify.sh \
			--source "${BASE}"/expectations/"${1}"/expectations_default \
      --user "${USER}" \
		"${2}"

  EXIT_STATUS=$?

  if [ $EXIT_STATUS -ne 0 ]; then
    exit $EXIT_STATUS
  fi

	"${BASE}"/image_verify.sh \
			--source "${BASE}"/expectations/"${1}"/expectations_overrides \
			--env-file "${BASE}"/expectations/"${1}"/image_env_overrides \
      --user "${USER}" \
		"${2}"

  EXIT_STATUS=$?
  exit $EXIT_STATUS
fi

exit 99
