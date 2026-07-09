#!/usr/bin/env bash

su -s /bin/bash hdfs -c "hdfs dfs -mkdir -p /cksums"
su -s /bin/bash hdfs -c "hdfs dfs -chown xrootd:xrootd /cksums"
su -s /bin/bash hdfs -c "hdfs dfs -mkdir -p /xrootd"
su -s /bin/bash hdfs -c "hdfs dfs -chown xrootd:xrootd /xrootd"

directories=$(python extract_directories.py)

for directory in $directories; do
    echo "Creating hdfs://$directory"
    su -s /bin/bash xrootd -c "hdfs dfs -mkdir -p $directory"
    echo "Creating hdfs:///cksums/$directory"
    su -s /bin/bash xrootd -c "hdfs dfs -mkdir -p /cksums/$directory"
done
