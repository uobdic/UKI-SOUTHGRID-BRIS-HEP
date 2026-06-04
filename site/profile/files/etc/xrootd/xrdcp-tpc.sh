#!/bin/sh
# from https://github.com/snafus/cephsum/blob/master/scripts/xrdcp-tpc.sh
# Original code
# /usr/bin/xrdcp --server -f $1 root://$XRDXROOTD_PROXY/$2

# Get the last two variables as SRC and DST, all others are assumed as additional arguments
# OTHERARGS="${@:1:$#-2}"
# DSTFILE="${@:$#:1}"
# SRCFILE="${@:$#-1:1}"

# /usr/bin/xrdcp $OTHERARGS --server -f $SRCFILE root://$XRDXROOTD_PROXY/$DSTFILE

set -- `getopt S: -S 1 $*`
while [ $# -gt 0 ]
do
  case $1 in
  -S)
      ((nstreams=$2-1))
      [ $nstreams -ge 1 ] && TCPstreamOpts="-S $nstreams"
      shift 2
      ;;
  --)
      shift
      break
      ;;
  esac
done

src=$1
dst=$2
xrdcp --server $TCPstreamOpts -f $src root://$XRDXROOTD_PROXY/${dst}