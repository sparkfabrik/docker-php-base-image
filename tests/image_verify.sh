#!/usr/bin/env bash

set -e

### Exit status ###
# 0:    success
# 1:    unsupported flag
# 2:    the specified source file (expectations) is not found
# 3:    the specified env file is not found
# 4:    the docker image to test is not given as argument
# 5:    the test function is called without any test variables
# 6:    some tests fails
# 7:    failed to find the docker image
# 8:    failed to find the docker test image
# 9:    docker run fails
# 10:   failed to discover the IP address of the docker image
# 11:   failed to get the ini data
# 12:   failed to get the extensions data
#####################

BASE=$(dirname "$0")

DEBUG=${DEBUG:-0}
DRY_RUN=0

WAIT_FOR_VER=2.1.3
WAIT_FOR_TIMEOUT=60

DOCKER_TEST_IMAGE="sparkfabrik/php-test-image"
DOCKER_TEST_IP=""
DOCKER_TEST_PORT=9000
DOCKER_TEST_HEADERS=""
DOCKER_TEST_INI=""
DOCKER_TEST_EXT=""
DOCKER_TEST_EXT_FUNCS=""

DOCKER_IMAGE=""
DOCKER_ENV=""
ENV_LIST=""
ENV_FILE=""

SOURCE_FILE=""

TEST_USER=""

CUR_TEST_VAR=""
CUR_TEST_VAL=""

print_dry_run() {
    PAD=40
    cat <<EOM
You are running this script in dry-run mode.
I will test the defined expectations as defined below:

### Generic variables ###
EOM
printf "%-${PAD}s %s\n" "DOCKER_TEST_IMAGE" "${DOCKER_TEST_IMAGE}"
printf "%-${PAD}s %s\n" "DOCKER_IMAGE" "${DOCKER_IMAGE}"
printf "%-${PAD}s %s\n" "ENV_LIST" "${ENV_LIST}"
printf "%-${PAD}s %s\n" "ENV_FILE" "${ENV_FILE}"
printf "%-${PAD}s %s\n" "SOURCE_FILE" "${SOURCE_FILE}"

if [ -n "${TEST_USER}" ]; then
    printf "%-${PAD}s %s\n" "CONTAINER_USER" "${TEST_USER}"
fi

cat <<EOM

### Defined variables ###
EOM

    while IFS= read -r line; do
      if [ -n "${line}" ]; then
        CUR_TEST_VAR=$(echo "${line}" | awk '{split($0,a,"="); print a[1]}')
        CUR_TEST_VAL=$(echo "${line}" | awk '{gsub(/\"/,""); split($0,a,"="); print a[2]}')
        printf "%-${PAD}s %s\n" "${CUR_TEST_VAR}" "${CUR_TEST_VAL}"
      fi
    done < <(grep -v '^#' "${SOURCE_FILE}")
}

show_usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTIONS] [EXPECTATIONS] <DOCKER IMAGE> [DOCKER TEST IMAGE]
Options:
    --help,-h                           Print this help message
    --dry-run                           The script will only print the expectations
    --env,-e LIST                       Defines the comma separated environment variables to pass to the container
    --env-file PATH                     Defines a path for a file which includes all the ENV variables to pass to
                                        the container image (these variables will override the --env defined ones)
    --fpm-port N                        Defines the PHP-FPM port, if missing the default 9000 port is used
    --source PATH                       Defines a path for a file which includes the desired expectations
    --user,-u STRING                    Defines the default user for the image
EOM
}

debug() {
  if [ -n "${1:-}" ] && [ "${DEBUG:-0}" -eq 1 ]; then
    echo "${1}"
  fi
}

process_docker_env() {
    if [ -n "${ENV_LIST}" ]; then
        # shellcheck disable=SC2001
        DOCKER_ENV="-e $(echo "${ENV_LIST}" | sed 's/,/ -e /g;')"
    fi
    if [ -n "${ENV_FILE}" ]; then
        if [ -f "${ENV_FILE}" ]; then
            DOCKER_ENV="${DOCKER_ENV} --env-file ${ENV_FILE}"
        else
            echo "Failed to process the env configuration"
            exit 3
        fi
    fi
}

begins_with_dash() {
    # shellcheck disable=SC2317
    case $1 in "-"*) true;; *) false;; esac;
}

# Process arguments
PARAMS=""
while [ -n "${1}" ]; do
    case "$1" in
        --help|-h) show_usage; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --env|-e) if [ -n "${ENV_LIST}" ]; then ENV_LIST="${ENV_LIST},${2}"; else ENV_LIST="${2}"; fi; shift 2 ;;
        --env-file) ENV_FILE="${2}"; if [ ! -f "${ENV_FILE}" ]; then exit 3; fi; shift 2 ;;
        --fpm-port) DOCKER_TEST_PORT="${2}"; shift 2 ;;
        --source) SOURCE_FILE="${2}"; if [ ! -f "${SOURCE_FILE}" ]; then exit 2; fi; shift 2 ;;
        --user|-u) TEST_USER="${2}"; shift 2 ;;
        -*) echo "Error: Unsupported flag $1" >&2; exit 1 ;;
        *) PARAMS="$PARAMS $1"; shift ;;
    esac
done

eval set -- "$PARAMS"

if [ -z "${1}" ]; then
    echo "Error: you must provide the docker image to test"
    exit 4
fi

DOCKER_IMAGE=${1}

if [ -n "${2}" ]; then
    DOCKER_TEST_IMAGE=${2}
fi

if [ $DRY_RUN -eq 1 ]; then
    print_dry_run
    exit 0
fi

# Check the expectations
test_for_ini() {
    LOC_EXIT_STATUS=5
    if [ -n "${CUR_TEST_VAR}" ] && [ -n "${CUR_TEST_VAL}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        CONTAINER_VAL=$(echo "${DOCKER_TEST_INI}" | grep "^${CUR_TEST_VAR} => " | awk '{print $3}')

        if [ "${CONTAINER_VAL}" != "${CUR_TEST_VAL}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=6
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="\e[32mOK\e[39m" || TEST_PASSED_STR="\e[31mFAIL\e[39m"
        echo "Testing the expectation for ${CUR_TEST_VAR}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            echo "Expected: ${CUR_TEST_VAL} - Actual value: ${CONTAINER_VAL}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt "$EXIT_STATUS" ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

test_for_module() {
    LOC_EXIT_STATUS=5
    if [ -n "${CUR_TEST_VAR}" ] && [ -n "${CUR_TEST_VAL}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        # shellcheck disable=SC2126
        CONTAINER_VAL=$(echo "${DOCKER_TEST_EXT}" | grep "${CUR_TEST_VAR}" | wc -l)

        if [ "${CONTAINER_VAL}" != "${CUR_TEST_VAL}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=6
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="\e[32mOK\e[39m" || TEST_PASSED_STR="\e[31mFAIL\e[39m"
        echo "Testing the expectation for module ${CUR_TEST_VAR}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            [ "${CUR_TEST_VAL}" -eq 0 ] && REQ_LOADED_STATE="not loaded" || REQ_LOADED_STATE="loaded"
            [ "${CONTAINER_VAL}" -eq 0 ] && ACT_LOADED_STATE="not loaded" || ACT_LOADED_STATE="loaded"
            echo "Expected: ${REQ_LOADED_STATE} - Actual value: ${ACT_LOADED_STATE}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

test_for_header() {
    LOC_EXIT_STATUS=5
    if [ -n "${CUR_TEST_VAR}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1

        if [ -z "${CUR_TEST_VAL}" ]; then
            debug "Test that the header is not present"
            # shellcheck disable=SC2126
            if [ "$(echo "${DOCKER_TEST_HEADERS}" | grep -i "^${CUR_TEST_VAR}: " | wc -l)" -ne 0 ]; then
                TEST_PASSED=0
                LOC_EXIT_STATUS=6
            fi
        else
            debug "Test header value"
            CONTAINER_VAL=$(echo "${DOCKER_TEST_HEADERS}" | grep -i "^${CUR_TEST_VAR}: " | awk '{print $2}')

            # shellcheck disable=SC2126
            if [ "$(echo "${CONTAINER_VAL}" | grep -E "${CUR_TEST_VAL}" | wc -l)" -ne 1 ]; then
                TEST_PASSED=0
                LOC_EXIT_STATUS=6
            fi
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="\e[32mOK\e[39m" || TEST_PASSED_STR="\e[31mFAIL\e[39m"
        echo "Testing the expectation for ${CUR_TEST_VAR}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            echo "Expected: ${CUR_TEST_VAL} - Actual value: ${CONTAINER_VAL}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

test_for_function() {
    LOC_EXIT_STATUS=5
    if [ -n "${CUR_TEST_VAR}" ] && [ -n "${CUR_TEST_VAL}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        CONTAINER_VAL=$(echo "${DOCKER_TEST_EXT_FUNCS}" | tail -n +3 | jq --raw-output ".${CUR_TEST_VAL}" | grep "${CUR_TEST_VAR}" | awk '{gsub(/"/,""); gsub(/,/,""); print $1}')

        if [ "${CONTAINER_VAL}" != "${CUR_TEST_VAR}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=6
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="\e[32mOK\e[39m" || TEST_PASSED_STR="\e[31mFAIL\e[39m"
        echo "Testing the expectation for function ${CUR_TEST_VAR} in module ${CUR_TEST_VAL}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            echo "Expected: ${CUR_TEST_VAR} - Actual value: ${CONTAINER_VAL}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

test_for_user() {
    LOC_EXIT_STATUS=5
    if [ -n "${CONTAINER_ID}" ] && [ -n "${CUR_TEST_VAL}" ]; then
        TEST_USER=""
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        CONTAINER_VAL=$(docker exec "${CONTAINER_ID}" ash -c "whoami 2>&1 | sed 's/whoami: //'")

        if [ "${CONTAINER_VAL}" != "${CUR_TEST_VAL}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=6
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="\e[32mOK\e[39m" || TEST_PASSED_STR="\e[31mFAIL\e[39m"
        echo "Testing the expectation for USER: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            echo "Expected: ${CUR_TEST_VAL} - Actual value: ${CONTAINER_VAL}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

if [ -z "$(docker images -q "${DOCKER_IMAGE}")" ]; then
    echo "Failed to find the docker image"
    exit 7
fi

if [ -z "$(docker images -q "${DOCKER_TEST_IMAGE}")" ]; then
    echo "Failed to find the docker test image"
    exit 8
fi

EXIT_STATUS=0

# Get "wait-for" script to wait until the docker image will be booted up
curl -Ls -o "${BASE}"/wait-for https://github.com/eficode/wait-for/releases/download/v${WAIT_FOR_VER}/wait-for && chmod +x "${BASE}"/wait-for

process_docker_env
RUNCMD="docker run ${DOCKER_ENV} -d -v ${PWD}/tests/php-test-scripts:/var/www/html ${DOCKER_IMAGE}"
debug "Docker run command: ${RUNCMD}"
if ! CONTAINER_ID=$(${RUNCMD}); then
    echo "Failed to start the docker image"
    exit 9
fi
if ! docker ps --no-trunc | grep "${CONTAINER_ID}"; then
    echo ""
    echo "Failed to start the docker image, with the following errors:"
    docker logs "${CONTAINER_ID}"
    echo ""
    # docker rm -vf ${CONTAINER_ID}
    exit 9
fi

debug "I will perform the tests on the container with id: ${CONTAINER_ID}"
debug "Find the container IP address: docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID}"
if ! DOCKER_TEST_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${CONTAINER_ID}"); then
    echo "Failed to discover the IP address of the docker image"
    exit 10
fi

debug "Wait for container readiness (${DOCKER_TEST_IP}:${DOCKER_TEST_PORT})"
debug "${BASE}/wait-for -t ${WAIT_FOR_TIMEOUT} ${DOCKER_TEST_IP}:${DOCKER_TEST_PORT}"
"${BASE}"/wait-for -t ${WAIT_FOR_TIMEOUT} "${DOCKER_TEST_IP}":"${DOCKER_TEST_PORT}"

debug "Get the INI output: docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_vars.php"
if ! DOCKER_TEST_INI=$(docker run --rm "${DOCKER_TEST_IMAGE}" "${DOCKER_TEST_IP}" "${DOCKER_TEST_PORT}" /var/www/html/print_vars.php); then
    echo "Failed to get the ini data"
    exit 11
fi

DOCKER_TEST_HEADERS=$(echo "${DOCKER_TEST_INI}" | awk -v 'RS=\n\r' '1;{exit}' | tr -d "\r")

debug "Get the EXT output: docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_loaded_ext.php"
if ! DOCKER_TEST_EXT=$(docker run --rm "${DOCKER_TEST_IMAGE}" "${DOCKER_TEST_IP}" "${DOCKER_TEST_PORT}" /var/www/html/print_loaded_ext.php); then
    echo "Failed to get the extensions data"
    exit 12
fi

debug "Get the EXT FUNCTIONS output: docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_functions_ext.php"
if ! DOCKER_TEST_EXT_FUNCS=$(docker run --rm "${DOCKER_TEST_IMAGE}" "${DOCKER_TEST_IP}" "${DOCKER_TEST_PORT}" /var/www/html/print_functions_ext.php); then
    echo "Failed to get the extensions data"
    exit 12
fi

while IFS= read -r line; do
    if [ -n "${line}" ]; then
        CUR_TEST_VAR=$(echo "${line}" | awk '{split($0,a,"="); print a[1]}')
        CUR_TEST_VAL=$(echo "${line}" | awk '{gsub(/"/,""); split($0,a,"="); print a[2]}')

        if [ "$(echo "${CUR_TEST_VAR}" | awk '$0 ~ /^MODULE_/ {print 1}')" = "1" ]; then
            CUR_TEST_VAR=$(echo "${CUR_TEST_VAR}" | awk '{gsub(/(MODULE_)|(_ENABLE)/,""); print tolower($0)}')
            debug "${CUR_TEST_VAR} equal to ${CUR_TEST_VAL} and this is module test"
            test_for_module
        elif [ "$(echo "${CUR_TEST_VAR}" | awk '$0 ~ /^FUNCTION_/ {print 1}')" = "1" ]; then
            CUR_TEST_VAR=$(echo "${CUR_TEST_VAR}" | awk '{gsub(/(FUNCTION_)/,""); print tolower($0)}')
            debug "${CUR_TEST_VAR} equal to ${CUR_TEST_VAL} and this is function test"
            test_for_function
        elif [ "$(echo "${CUR_TEST_VAR}" | awk '$0 ~ /^HEADER_/ {print 1}')" = "1" ]; then
            CUR_TEST_VAR=$(echo "${CUR_TEST_VAR}" | awk '{gsub(/(HEADER_)/,""); print tolower($0)}')
            debug "${CUR_TEST_VAR} equal to ${CUR_TEST_VAL} and this is header test"
            test_for_header
        elif [ "${CUR_TEST_VAR}" = "CONTAINER_USER" ]; then
            test_for_user
        else
            debug "${CUR_TEST_VAR} equal to ${CUR_TEST_VAL} and this is ini test"
            test_for_ini
        fi
    fi
done < <(grep -v '^#' "${SOURCE_FILE}")

if [ -n "${TEST_USER}" ]; then
    CUR_TEST_VAL="${TEST_USER}"
    test_for_user
fi

debug "Docker stop command: docker stop ${CONTAINER_ID} >/dev/null 2>&1"
docker stop "${CONTAINER_ID}" >/dev/null 2>&1

if [ $EXIT_STATUS -eq 0 ]; then
    echo -e "\e[32mSUCCESS, all tests passed\e[39m"
else
    echo -e "\e[31mFAIL, some tests failed\e[39m"
fi
exit $EXIT_STATUS
