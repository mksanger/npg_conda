#! /bin/bash

set -e -u -x

mkdir -p $CHANNEL_DIR
mkdir -p $BUILD_DIR

wget --quiet $MINICONDA -O ~/miniconda.sh
/bin/bash ~/miniconda.sh -b -p ~/miniconda
~/miniconda/bin/conda clean -tipsy

if [ -e ~/.bashrc ] ; then
    cp ~/.bashrc ~/.bashrc.bak
fi

echo ". ~/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc

. ~/miniconda/etc/profile.d/conda.sh
conda activate base
conda config --set auto_update_conda False
conda config --prepend channels "$WSI_CONDA_CHANNEL"
conda config --append channels conda-forge

pip install -r ./tools/requirements.txt
pip install awscli-plugin-endpoint

aws configure set plugins.endpoint awscli_plugin_endpoint
aws configure set s3.endpoint_url $S3_URL
aws configure set s3api.endpoint_url $S3_URL

aws s3 sync "$CHANNEL_REM" "$CHANNEL_DIR"
