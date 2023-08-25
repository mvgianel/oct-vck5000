#!/bin/sh
  
SCRIPTNAME=$0
#
GENIUSER=`geni-get user_urn | awk -F+ '{print $4}'`
if [ $? -ne 0 ]; then
echo "ERROR: could not run geni-get user_urn!"
exit 1
fi
if [ $USER != $GENIUSER ]; then
sudo -u $GENIUSER $SCRIPTNAME
exit $?
fi
HOMEDIR="/users/"
echo "/users/$USER"
