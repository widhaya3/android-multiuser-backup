#!/bin/bash

. $(dirname $0)/config

function usage {
	echo "usage: $0 DEVICE USER_ID|all PACKAGES...|all"
	echo "exam1: $0 XXXXXX all all"
	echo "exam2: $0 XXXXXX 0 com.google.android.youtube"
}
if [ ! "$1" ]; then
	usage
	$A0 devices
	exit 1
fi

set -e

#$A shell su -c \'rm -rf $devdatadir\'
#$A shell rm -rf $devdatadir
#
#$A shell mkdir -p $devdatadir
#
#$A push $(dirname $0)/backup.sh $devtmpdir/
#$A push $(dirname $0)/config $devtmpdir/
##$A shell su -c \'sh $devtmpdir/backup.sh $*\'
#$A shell sh $devtmpdir/backup.sh $*
#$A pull $devdatadir $localdatadir
##$A shell su -c \'rm -rf $devdatadir\'
#$A shell rm -rf $devdatadir
#$A shell rm -f $devtmpdir/backup.sh
#$A shell rm -f $devtmpdir/config

DEVICE=$1
AUID=$2
A="$A0 -s $DEVICE"
AS="$A shell"

mkdir -p $LBASE
rm -rf $LBASE/*

echo "Retrive users and packages"

echo "$AS \"pm list packages | cut -f2 -d':'\" | tr -d '\r' > $LBASE/pall.txt"
$AS "pm list packages | cut -f2 -d':'" | tr -d '\r' > $LBASE/pall.txt

echo "$AS \"pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{'\" | tr -d '\r' > $LBASE/alluser.txt"
$AS "pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{'" | tr -d '\r' > $LBASE/alluser.txt

ALL_UID="`cat $LBASE/alluser.txt`"

echo "$AS \"pm list package -e --user \$AUID | cut -f2 -d':'\" | tr -d '\r' > $LBASE/puser_${AUID}.txt"
if [ "$AUID" == "all" ]; then
	for AUID in $ALL_UID; do
		$AS "pm list package -e --user $AUID | cut -f2 -d':'" | tr -d '\r' > $LBASE/puser_${AUID}.txt
	done
else
	$AS "pm list package -e --user $AUID | cut -f2 -d':'" | tr -d '\r' > $LBASE/puser_${AUID}.txt
fi

echo 
echo "Next, reboot to TWRP-recovery (adb reboot recovery | adb reboot bootloader && fastboot boot twrp-xxxx)"
echo "Then, run $(dirname $0)/backup.sh $*"
