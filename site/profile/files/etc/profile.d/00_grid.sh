#!/usr/bin/timeout -s9 10s

export PATH=/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin:$PATH

if [ "x$USER" != "xroot" ]
then
  #source /cvmfs/grid.cern.ch/umd-c7wn-latest/etc/profile.d/setup-c7-wn-example.sh
  source /cvmfs/grid.cern.ch/alma9-ui-test/etc/profile.d/setup-alma9-test.sh
else
  echo "User root detected - not loading grid setup"
fi
