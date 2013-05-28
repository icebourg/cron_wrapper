#!/bin/bash

#######################################################################
# cron_wrapper.sh
#######################################################################
# A simple wrapper to handle all that crap you might want in cron. This
# automatically handles locking so a cron job will run only one at
# a time and also optionally allows you to sleep a random amount of
# time so that cron jobs that run on a wide range of machines won't
# necessarily all run at the same time.
#######################################################################

usage()
{
cat << EOF
Usage:
  $0 -n name [--lockfile /path/lock.pid] [--kill] [-sleep max sleep time] /path/to/real/script.sh
    

This script is meant to wrap things you would like to run in cron.
It automatically handles lock files. And you can specify a sleep time
with -s as a max, random sleep time before the command is executed.
Random sleep time is a useful way of ensuring jobs do not run all at the
same time on a cluster of machines.

OPTIONS

  --lockfile /absolute/path
    The full path to the lockfile we will check.

  --kill 
    If we find the lock from a previous cron run, we will kill -9 it.
      Otherwise we will just refuse to run and let the other one run.
      
  --sleep seconds
    The maximum number of seconds to randomly sleep.

EOF
}

LOCKFILE=/var/run/cron.pid
SLEEP=0
KILL=0

while [ $# -gt 0 ]
do
  case $1 in
    -*lockfile)
      shift
      LOCKFILE=$1
      shift
      ;;
    -*kill)
      shift
      KILL=1
      ;;
    -*sleep)
      shift
      SLEEP=$1
      shift
      ;;
    -*help)
      usage
      exit
      ;;
    *)
      break
      ;;
  esac
done


# see if a lock file already exists
if [[ -f "$LOCKFILE" ]]
then
  if [[ "$KILL" -gt "0" ]]
  then
    kill -9 `cat $LOCKFILE`
    rm -rf $LOCKFILE
  else
    echo "Lock file exists, exiting."
    exit 1
  fi  
fi

# make our own lock file
echo $$ >> $LOCKFILE

if [[ "$SLEEP" -gt 0 ]]
then
  sleep $[ ( $RANDOM % $SLEEP ) ]s
fi

# whatever's left is what we're wrapping, so run it
eval $*

rm $LOCKFILE