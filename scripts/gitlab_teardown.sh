#! /bin/bash

set -e -u -x

rm -rf ~/tmp
rm -rf ~/miniconda*
if [ -e ~/.bashrc.bak ] ; then
    mv ~/.bashrc.bak ~/.bashrc
fi
