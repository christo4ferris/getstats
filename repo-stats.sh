#!/bin/bash

# provide debugging output when desired
function DEBUG {
    [ "$GITDM_DEBUG" == "on" ] && echo "DEBUG: $1"
}

if [ $# -ne 3 ]; then
    echo "Usage $0 since-date repo org"
    exit 1
fi

# enable/disable debugging output
GITDM_DEBUG=${GITDM_DEBUG:-"off"}

# determine if a given parameter is a date matching the format YYYY-MM-DD,
# i.e. 2013-09-13   This is used to decide if git should specify a start
# date with '--since YYYY-MM-DD' rather than use an absolute changeset id
function IS_DATE {
    [[ $1 =~ ^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$ ]]
}

SINCE=${1:-2016-02-11}
# use start of Hyperledger org if not date
if ! IS_DATE $SINCE; then
  SINCE=2016-02-11
  echo "WARNING: Using 2016-02-11 start. Use YYYY-MM-DD format date"
fi
GITBASE=$(pwd)/repos
RELEASE=${2}-$(date "+%Y-%m-%d")
BASEDIR=$(pwd)
CONFIGDIR=$(pwd)/config
TEMPDIR=${TEMPDIR:-$(mktemp -d $(pwd)/dmtmp-XXXXXX)}
GITLOGARGS="--no-merges --numstat -M --find-copies-harder"
REPOBASE=http://github.com/$3
echo ${2} > lists/project.txt
PROJECTS=lists/project.txt

UPDATE_GIT=${UPDATE_GIT:-y}
GIT_STATS=${GIT_STATS:-y}
REMOVE_TEMPDIR=${REMOVE_TEMPDIR:-y}
TIMESTAMP=`date`
# brief header to prepend to all of the analysis results
OUTPUT_HEADER="Statistics for ${2} generated at ${TIMESTAMP}"

source ./stats.sh
