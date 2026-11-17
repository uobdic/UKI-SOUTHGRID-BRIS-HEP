#!/usr/bin/env bash

echo "## Packages"
echo "### xrootd"
echo ""
echo "| package | version | source |"
echo "--- | --- | ---|"
cat /etc/xrootd_info/installed_packages.info
echo ""

echo "Python packages"
/miniconda/bin/python -m pip list >> /etc/xrootd_info/python_packages.info
cat /etc/xrootd_info/python_packages.info
