#! /bin/bash

set -e -u -x

rsync -av --include='*.tar.bz2' --exclude='*' $BUILD_DIR/linux-64/ $CHANNEL_DIR/generic/linux-64/

conda index $CHANNEL_DIR/generic

aws s3 sync --acl public-read --acl bucket-owner-full-control --exclude '*/.cache/*' $CHANNEL_DIR/generic $CHANNEL_REM
