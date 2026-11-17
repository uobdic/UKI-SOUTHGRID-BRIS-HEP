#!/usr/bin/env bash

RESULT=$(xrdsum --verbose  --debug --log-file /var/log/xrootd/clustered/checksum.log get --file-system POSIX --store-result "$1")
ECODE=$?

# XRootD expects return on stdout - checksum followed by a new line
printf "%s\n" "$RESULT"
# printf "%s" "$RESULT"
exit "$ECODE"
