#!/usr/bin/env bash

# $1 is database name
dbname="$1"
# $2 is script name
sqlscript="$2"

username="postgres"
export PGPASSWORD="password123-"

if [ -z "$dbname" ]; then
    echo "Missing database name"
    exit 1
fi

if [ ! -f "$sqlscript" ]; then
    echo "Missing sql script"
    exit 2
fi

set -o xtrace
cd /usr/lib/postgresql/16/bin
./psql  -h "localhost" -U "${username}" -d "${dbname}" -a -f "${sqlscript}"
set +o xtrace