#!/bin/bash -l

ERROR=""
USAGE="USAGE: env.sh <DISTRIBUTION> <TARGET>"

if [ -z "$1" ]; then
    ERROR="ERROR! A distribution must be supplied\n$USAGE"
elif [ -z "$2" ]; then
    ERROR="ERROR! A target must be supplied\n$USAGE"
fi

if [[ "$ERROR" == "" ]]; then
    case "$1" in
        "native")
            export ZSYS_DISTRIBUTION=native
            ;;
        *)
            ERROR="ERROR! Distribution $1 is unknown"
            ;;
    esac
fi

if [[ "$ERROR" == "" ]]; then
    case "$2" in
        "unittest")
            export ZSYS_TARGET=unittest
            ;;
        *)
            ERROR="ERROR! Target $1 is unknown"
            ;;
    esac
fi

if [[ "$ERROR" == "" ]]; then
    DIR=$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)
    export ZSYS_ROOT=$(dirname $(dirname ${DIR}))
    export LD_LIBRARY_PATH=${ZSYS_ROOT}/build/${ZSYS_DISTRIBUTION}/${ZSYS_TARGET}/lib
else
    echo -e $ERROR
fi

