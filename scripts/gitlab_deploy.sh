#! /bin/bash

set -e -u -x

cp $BUILD_DIR/linux_64/*.tar.bz2 $CHANNEL_DIR/linux_64/
conda index $CHANNEL_DIR
aws s3 sync --acl public-read --acl bucket-owner-full-control --exclude '*/.cache/*' $CHANNEL_DIR $CHANNEL
