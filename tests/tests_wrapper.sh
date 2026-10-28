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

  if [ $EXIT_STATUS -ne 0 ]; then
    exit $EXIT_STATUS
  fi

  # gRPC ships disabled: check that an ini line loads it with its default settings.
  if docker run --rm --entrypoint php "${2}" -d extension=grpc \
    -r 'exit(extension_loaded("grpc") && ini_get("grpc.enable_fork_support") === "1" && ini_get("grpc.poll_strategy") === "epoll1" ? 0 : 1);'; then
    echo "Testing that grpc loads when enabled: OK"
  else
    echo "Testing that grpc loads when enabled: FAIL"
    exit 6
  fi

  exit 0
fi

exit 99
