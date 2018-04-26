#!/bin/sh

set -e

n=`expr $CPU_COUNT / 4 \| 1`

pushd samtools
./configure --prefix="$PREFIX" --without-curses
make -j $n
ln -s . include
popd

pushd npg_qc_utils
pushd fastq_summ
mkdir -p build
make -j $n INCLUDES="-I. -I$SRC_DIR/samtools -I$PREFIX/include" SAMTOOLSLIBPATH="-L$SRC_DIR/samtools -L$PREFIX/lib"
make install installdir="$PREFIX/bin/"
popd
popd