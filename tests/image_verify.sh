#!/bin/sh

### Exit status ###
# 0: success
# 1: unsupported flag
# 2: the docker image to test is not given as argument
# 3: the specified env file is not found
# 4: the specified source file (expectations) is not found
# 5: docker run fails
# 6: failed to discover the IP address of the docker image
# 7: failed to get the ini data
# 8: failed to get the extensions data
#####################

DEBUG=${DEBUG:-0}
DRY_RUN=0

DOCKER_TEST_IMAGE="sparkfabrik/php-test-image"
DOCKER_TEST_IP=""
DOCKER_TEST_PORT=9000
DOCKER_TEST_INI=""
DOCKER_TEST_EXT=""

DOCKER_IMAGE=""
DOCKER_ENV=""
ENV_LIST=""
ENV_FILE=""

SOURCE_FILE=""

# Dockerfile variables
REALPATH_CACHE_SIZE=""
UPLOAD_MAX_FILE_SIZE=""
POST_MAX_SIZE=""
MAX_EXECUTION_TIME=""

FPM_MAX_CHILDREN=""
FPM_START_SERVERS=""
FPM_MIN_SPARE_SERVERS=""
FPM_MAX_SPARE_SERVERS=""

# Entrypoint variables
MEMORY_LIMIT=""
TIMEZONE=""
OPCACHE_ENABLE=""
OPCACHE_MEMORY=""

REDIS_ENABLE=""
MEMCACHED_ENABLE=""
XDEBUG_ENABLE=""

MAILHOG_ENABLE=""
MAILHOG_HOST=""
MAILHOG_PORT=""

print_dry_run() {
    cat <<EOM
You are running this script in dry-run mode.
I will test the defined expectations as defined below:

### Generic variables ###
DOCKER_TEST_IMAGE.......................${DOCKER_TEST_IMAGE}
DOCKER_IMAGE............................${DOCKER_IMAGE}
ENV_LIST................................${ENV_LIST}
ENV_FILE................................${ENV_FILE}
SOURCE_FILE.............................${SOURCE_FILE}

### Dockerfile variables ###
REALPATH_CACHE_SIZE.....................${REALPATH_CACHE_SIZE}
UPLOAD_MAX_FILE_SIZE....................${UPLOAD_MAX_FILE_SIZE}
POST_MAX_SIZE...........................${POST_MAX_SIZE}
MAX_EXECUTION_TIME......................${MAX_EXECUTION_TIME}
FPM_MAX_CHILDREN........................${FPM_MAX_CHILDREN}
FPM_START_SERVERS.......................${FPM_START_SERVERS}
FPM_MIN_SPARE_SERVERS...................${FPM_MIN_SPARE_SERVERS}
FPM_MAX_SPARE_SERVERS...................${FPM_MAX_SPARE_SERVERS}

### Entrypoint variables ###
MEMORY_LIMIT............................${MEMORY_LIMIT}
TIMEZONE................................${TIMEZONE}
OPCACHE_ENABLE..........................${OPCACHE_ENABLE}
OPCACHE_MEMORY..........................${OPCACHE_MEMORY}
REDIS_ENABLE............................${REDIS_ENABLE}
MEMCACHED_ENABLE........................${MEMCACHED_ENABLE}
XDEBUG_ENABLE...........................${XDEBUG_ENABLE}
MAILHOG_ENABLE..........................${MAILHOG_ENABLE}
MAILHOG_HOST............................${MAILHOG_HOST}
MAILHOG_PORT............................${MAILHOG_PORT}
EOM
}

show_usage() {
    cat <<EOM
Usage: $(basename $0) [OPTIONS] [EXPECTATIONS] <DOCKER IMAGE> [DOCKER TEST IMAGE]
Options:
    --help,-h                           Print this help message
    --dry-run                           The script will only print the expectations
    --env,-e LIST                       Defines the comma separated environment variables to pass to the container
    --env-file PATH                     Defines a path for a file which includes all the ENV variables to pass to
                                        the container image (these variables will override the --env defined ones)
    --fpm-port N                        Defines the PHP-FPM port, if missing the default 9000 port is used
    --source PATH                       Defines a path for a file which includes the desired expectations
Expectations:
    ### Dockerfile variables ###
    --realpath-cache-size STRING        Defines the expected value for PHP_REALPATH_CACHE_SIZE
    --upload-max-file-size STRING       Defines the expected value for UPLOAD_MAX_FILE_SIZE
    --post-max-size STRING              Defines the expected value for POST_MAX_SIZE
    --max-execution-time STRING         Defines the expected value for MAX_EXECUTION_TIME
    --fpm-max-children N                Defines the expected value for FPM_MAX_CHILDREN
    --fpm-start-servers N               Defines the expected value for FPM_START_SERVERS
    --fpm-min-spare-servers N           Defines the expected value for FPM_MIN_SPARE_SERVERS
    --fpm-max-spare-servers N           Defines the expected value for FPM_MAX_SPARE_SERVERS

    ### Entrypoint variables ###
    --memory-limit,-ml STRING           Defines the expected value for PHP_MEMORY_LIMIT
    --timezone,-tz STRING               Defines the expected value for PHP_TIMEZONE
    --opcache-enable [1|0]              Defines the expected value for PHP_OPCACHE_ENABLE
    --opcache-memory STRING             Defines the expected value for PHP_OPCACHE_MEMORY
    --redis-enable [1|0]                Defines the redis module load expectation
    --memcached-enable [1|0]            Defines the memcached module load expectation
    --xdebug-enable [1|0]               Defines the xdebug module load expectation
    --mailhog-enable [1|0]              Defines the mailhog module load expectation
    --mailhog-host STRING               Defines the expected value for mailhog host
    --mailhog-port N                    Defines the expected value for mailhog port
EOM
}

process_docker_env() {
    if [ -n "${ENV_LIST}" ]; then
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
    case $1 in "-"*) true;; *) false;; esac;
}

# Process arguments
PARAMS=""
while [ -n "${1}" ]; do
    case "$1" in
        --help|-h) show_usage; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --env|-e) if [ -n "${ENV_LIST}" ]; then ENV_LIST="${ENV_LIST},${2}"; else ENV_LIST="${2}"; fi; shift 2 ;;
        --env-file) ENV_FILE="${2}"; shift 2 ;;
        --fpm-port) DOCKER_TEST_PORT="${2}"; shift 2 ;;
        --source) SOURCE_FILE="${2}"; if [ -f "${SOURCE_FILE}" ]; then . "${SOURCE_FILE}"; if [ $? -ne 0 ]; then exit 4; fi; fi; shift 2 ;;
        --realpath-cache-size) REALPATH_CACHE_SIZE="${2}"; shift 2 ;;
        --upload-max-file-size) UPLOAD_MAX_FILE_SIZE="${2}"; shift 2 ;;
        --post-max-size) POST_MAX_SIZE="${2}"; shift 2 ;;
        --max-execution-time) MAX_EXECUTION_TIME="${2}"; shift 2 ;;
        --fpm-max-children) FPM_MAX_CHILDREN="${2}"; shift 2 ;;
        --fpm-start-servers) FPM_START_SERVERS="${2}"; shift 2 ;;
        --fpm-min-spare-servers) FPM_MIN_SPARE_SERVERS="${2}"; shift 2 ;;
        --fpm-max-spare-servers) FPM_MAX_SPARE_SERVERS="${2}"; shift 2 ;;
        --memory-limit|-ml) MEMORY_LIMIT="${2}"; shift 2 ;;
        --timezone|-tz) TIMEZONE="${2}"; shift 2 ;;
        --opcache-enable) OPCACHE_ENABLE="${2}"; shift 2 ;;
        --opcache-memory) OPCACHE_MEMORY="${2}"; shift 2 ;;
        --redis-enable) REDIS_ENABLE="${2}"; shift 2 ;;
        --memcached-enable) MEMCACHED_ENABLE="${2}"; shift 2 ;;
        --xdebug-enable) XDEBUG_ENABLE="${2}"; shift 2 ;;
        --mailhog-enable) MAILHOG_ENABLE="${2}"; shift 2 ;;
        --mailhog-host) MAILHOG_HOST="${2}"; shift 2 ;;
        --mailhog-port) MAILHOG_PORT="${2}"; shift 2 ;;
        -*|--*=) echo "Error: Unsupported flag $1" >&2; exit 1 ;;
        *) PARAMS="$PARAMS $1"; shift ;;
    esac
done

eval set -- "$PARAMS"

if [ -z "${1}" ]; then
    echo "Error: you must provide the docker image to test"
    exit 2
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
    LOC_EXIT_STATUS=4
    if [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        CONTAINER_VAL=$(echo "${DOCKER_TEST_INI}" | grep "${1}" | awk '{print $3}')
        
        if [ "${CONTAINER_VAL}" != "${2}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=1
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="OK" || TEST_PASSED_STR="FAIL"
        echo "Testing the expectation for ${3}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            echo "Expected: ${2} - Actual value: ${CONTAINER_VAL}"
            echo ""
        fi
    fi

    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi
    
    return $LOC_EXIT_STATUS
}

test_for_module() {
    LOC_EXIT_STATUS=4
    if [ -n "${1}" ] && [ -n "${2}" ]; then
        LOC_EXIT_STATUS=0
        TEST_PASSED=1
        CONTAINER_VAL=$(echo "${DOCKER_TEST_EXT}" | grep "${1}" | wc -l)
        
        if [ "${CONTAINER_VAL}" = "${3}" ]; then
            TEST_PASSED=0
            LOC_EXIT_STATUS=1
        fi

        [ $TEST_PASSED -eq 1 ] && TEST_PASSED_STR="OK" || TEST_PASSED_STR="FAIL"
        echo "Testing the expectation for module ${1}: ${TEST_PASSED_STR}"
        if [ $TEST_PASSED -ne 1 ]; then
            [ ${2} -eq 0 ] REQ_LOADED_STATE="not loaded" || REQ_LOADED_STATE="loaded"
            [ ${CONTAINER_VAL} -eq 0 ] ACT_LOADED_STATE="not loaded" || ACT_LOADED_STATE="loaded"
            echo "Expected: ${REQ_LOADED_STATE} - Actual value: ${ACT_LOADED_STATE}"
            echo ""
        fi
    fi
    
    if [ $LOC_EXIT_STATUS -ne 0 ] && [ $LOC_EXIT_STATUS -gt $EXIT_STATUS ]; then
        EXIT_STATUS=$LOC_EXIT_STATUS
    fi

    return $LOC_EXIT_STATUS
}

EXIT_STATUS=0

process_docker_env
if [ $DEBUG -eq 1 ]; then
    echo "Docker run command: docker run ${DOCKER_ENV} --rm -d -v ${PWD}/tests/php-test-scripts:/var/www/html ${DOCKER_IMAGE}"
fi
CONTAINER_ID=$(docker run ${DOCKER_ENV} --rm -d -v ${PWD}/tests/php-test-scripts:/var/www/html ${DOCKER_IMAGE})
if [ $? -ne 0 ]; then
    echo "Failed to start the docker image"
    exit 5
fi

if [ $DEBUG -eq 1 ]; then
    echo "Find the container IP address: docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID}"
fi
DOCKER_TEST_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID})
if [ $? -ne 0 ]; then
    echo "Failed to discover the IP address of the docker image"
    exit 6
fi

if [ $DEBUG -eq 1 ]; then
    echo "Get the INI output: docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_vars.php"
fi
DOCKER_TEST_INI=$(docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_vars.php)
if [ $? -ne 0 ]; then
    echo "Failed to get the ini data"
    exit 7
fi

if [ $DEBUG -eq 1 ]; then
    echo "Get the EXT output: docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_loaded_ext.php"
fi
DOCKER_TEST_EXT=$(docker run --rm ${DOCKER_TEST_IMAGE} ${DOCKER_TEST_IP} ${DOCKER_TEST_PORT} /var/www/html/print_loaded_ext.php)
if [ $? -ne 0 ]; then
    echo "Failed to get the extensions data"
    exit 8
fi

if [ $DEBUG -eq 1 ]; then
    echo "I will perform the tests on the container with id: ${CONTAINER_ID}"
fi

if [ -n "${REALPATH_CACHE_SIZE}" ]; then
    test_for_ini "PHP_REALPATH_CACHE_SIZE" "${REALPATH_CACHE_SIZE}" "REALPATH_CACHE_SIZE"
fi
if [ -n "${UPLOAD_MAX_FILE_SIZE}" ]; then
    test_for_ini "PHP_UPLOAD_MAX_FILE_SIZE" "${UPLOAD_MAX_FILE_SIZE}" "UPLOAD_MAX_FILE_SIZE"
fi
if [ -n "${POST_MAX_SIZE}" ]; then
    test_for_ini "PHP_POST_MAX_SIZE" "${POST_MAX_SIZE}" "POST_MAX_SIZE"
fi
if [ -n "${MAX_EXECUTION_TIME}" ]; then
    test_for_ini "PHP_MAX_EXECUTION_TIME" "${MAX_EXECUTION_TIME}" "MAX_EXECUTION_TIME"
fi

if [ -n "${FPM_MAX_CHILDREN}" ]; then
    test_for_ini "PHP_FPM_MAX_CHILDREN" "${FPM_MAX_CHILDREN}" "FPM_MAX_CHILDREN"
fi
if [ -n "${FPM_START_SERVERS}" ]; then
    test_for_ini "PHP_FPM_START_SERVERS" "${FPM_START_SERVERS}" "FPM_START_SERVERS"
fi
if [ -n "${FPM_MIN_SPARE_SERVERS}" ]; then
    test_for_ini "PHP_FPM_MIN_SPARE_SERVERS" "${FPM_MIN_SPARE_SERVERS}" "FPM_MIN_SPARE_SERVERS"
fi
if [ -n "${FPM_MAX_SPARE_SERVERS}" ]; then
    test_for_ini "PHP_FPM_MAX_SPARE_SERVERS" "${FPM_MAX_SPARE_SERVERS}" "FPM_MAX_SPARE_SERVERS"
fi

# Entrypoint variables
if [ -n "${MEMORY_LIMIT}" ]; then
    test_for_ini "PHP_MEMORY_LIMIT" "${MEMORY_LIMIT}" "MEMORY_LIMIT"
fi
if [ -n "${TIMEZONE}" ]; then
    test_for_ini "PHP_TIMEZONE" "${TIMEZONE}" "TIMEZONE"
fi
if [ -n "${OPCACHE_ENABLE}" ]; then
    test_for_ini "PHP_OPCACHE_ENABLE" "${OPCACHE_ENABLE}" "OPCACHE_ENABLE"
fi
if [ -n "${OPCACHE_MEMORY}" ]; then
    test_for_ini "PHP_OPCACHE_MEMORY" "${OPCACHE_MEMORY}" "OPCACHE_MEMORY"
fi

if [ -n "${REDIS_ENABLE}" ]; then
    test_for_module "redis" "${REDIS_ENABLE}"
fi
if [ -n "${MEMCACHED_ENABLE}" ]; then
    test_for_module "memcached" "${MEMCACHED_ENABLE}"
fi
if [ -n "${XDEBUG_ENABLE}" ]; then
    test_for_module "xdebug" "${XDEBUG_ENABLE}"
fi

if [ -n "${MAILHOG_ENABLE}" ]; then
    test_for_ini "MAILHOG_ENABLE" "${MAILHOG_ENABLE}" "MAILHOG_ENABLE"
fi
if [ -n "${MAILHOG_HOST}" ]; then
    test_for_ini "MAILHOG_HOST" "${MAILHOG_HOST}" "MAILHOG_HOST"
fi
if [ -n "${MAILHOG_PORT}" ]; then
    test_for_ini "MAILHOG_PORT" "${MAILHOG_PORT}" "MAILHOG_PORT"
fi

if [ $DEBUG -eq 1 ]; then
    echo "Docker stop command: docker stop ${CONTAINER_ID} >/dev/null 2>&1"
fi
docker stop ${CONTAINER_ID} >/dev/null 2>&1

if [ $EXIT_STATUS -eq 0 ]; then
    echo "SUCCESS, all tests passed"
else
    echo "FAIL, some tests failed"
fi
exit $EXIT_STATUS
