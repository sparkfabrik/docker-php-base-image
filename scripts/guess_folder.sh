#!/bin/sh
# shellcheck disable=SC3040

set -u

# This script returns the base folder for the desired PHP version.
# It tries to find the corresponding folder in the filesystem, using this precedence:
# 1. full version name (e.g.: 7.4.29-fpm-alpine3.15)
# 2. full semver version (e.g.: 7.4.9)
# 3. major.minor (e.g.: 7.4)
# 4. only major version (e.g.: 7)
#
# If no folder was found in the filesystem after the guessing process, the script will exit with errors.

# Check if there is an input
if [ -z "${1}" ]; then
  echo "You need to provide a valid PHP version to guess the folder for its configuration"
  exit 2
fi

# Check if the input is a valid semver
echo "${1}" | grep -q -E '^[0-9]+.[0-9]+.[0-9]+'
VALID_SEMVER=$?
if [ "${VALID_SEMVER}" -ne 0 ] ; then
  echo "You need to provide a valid PHP version to guess the folder for its configuration"
  exit 3
fi

PHPVER="${1}"

# Guessing folder
# Full version (x.y.z<suffix>)
DIR="./${PHPVER}"
if [ ! -d "${DIR}" ]; then
  # Full semver (x.y.z)
  DIR="./$(echo "${PHPVER}" | sed -n 's|\([[:digit:]]*\)\.\([[:digit:]]*\)\.\([[:digit:]]*\).*|\1.\2.\3|p')"
  if [ ! -d "${DIR}" ]; then
    # major.minor (x.y)
    DIR="./$(echo "${PHPVER}" | sed -n 's|\([[:digit:]]*\)\.\([[:digit:]]*\)\.\([[:digit:]]*\).*|\1.\2|p')"
    if [ ! -d "${DIR}" ]; then
      # Only major (x)
      DIR="./$(echo "${PHPVER}" | sed -n 's|\([[:digit:]]*\)\.\([[:digit:]]*\)\.\([[:digit:]]*\).*|\1|p')"
      if [ ! -d "${DIR}" ]; then
        echo "There is no a valid folder for this PHP version"
        exit 1
      fi
    fi
  fi
fi

if [ ! -d "${DIR}" ] || [ ! -f "${DIR}/Dockerfile" ]; then
  echo "There folder does not exists or the Dockerfile is missing"
  exit 4
fi

echo "${DIR}"
