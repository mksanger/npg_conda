#! /bin/bash

set -e -u -x


cp $CHANNEL_DIR $BUILD_DIR

./tools/bin/recipebook --changes $COMPARE_BRANCH recipes |
  ./tools/bin/build --recipes-dir . --artefacts-dir $BUILD_DIR \ 
  --conda_build_image $CONDA_IMAGES --remove_container
    
./tools/bin/recipebook --changes $COMPARE_BRANCH red_recipes |
  ./tools/bin/build --recipes-dir . --artefacts-dir $BUILD_DIR \ 
  --conda_build_image $CONDA_IMAGES --remove_container
