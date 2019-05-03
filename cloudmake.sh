#!/usr/bin/env bash

SELFDIR="$(cd "$(dirname "$(readlink "$0")")"; pwd -P)"

CLOUDMAKE_DEPS=$SELFDIR/cloudmake make --no-print-directory -f $SELFDIR/cloud.mak $@
