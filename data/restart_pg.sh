#!/usr/bin/env bash
set -o xtrace
cd /usr/lib/postgresql/17/bin
pg_ctl restart --mode=fast
set +o xtrace
