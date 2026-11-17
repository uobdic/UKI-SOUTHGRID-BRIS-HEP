#!/usr/bin/env bash

dnf list installed | egrep "xrootd|voms|macaroons|scitokens"  | awk '{printf("|%-30s| %30s | %15s |\n", $1, $2, $3)}' | sed 's/@//g'
