#!/bin/bash
#*** RUN IN LINUX SHELL ***

. $(dirname $0)/config

function usage {
    echo "usage: $0 DEVICE USER_ID|all PACKAGES...|all"
    echo "exam1: $0 XXXXXXXXXXXXXXXX all all"
    echo "exam2: $0 XXXXXXXXXXXXXXXX 0 com.google.android.youtube"
    echo "step: adb-backup.sh -> boot recovery (or rooted) -> backup.sh"
}
if [ ! "$1" ]; then
    usage
    $A0 devices
    exit 1
fi

set -e

DEVICE=$1
shift
AUID=$1
shift
PKG=$1

A="$A0 -s $DEVICE"
AS="$A shell"

if [ -z "$DEVICE" -o -z "$AUID" -o -z "$PKG" ]; then
  echo "Usage $0 <DEVICE> <AUID> <PKG>"
  exit 0
fi

LBASE="$LDATADIR"
mkdir -p $LBASE/{apks,data}

PKGS="$*"
AUIDS="$AUID"

$AS mount -a

# Backup all installed packages?
if [ "$PKG" = "all" ]; then
  #pkgs="$(pm list packages | cut -f2 -d':')"
  #PRE-REQUISITE BEFORE ENTER RECOVERY:
  #  adb shell "pm list packages | cut -f2 -d':' > $LBASE/pall.txt"
  #  adb shell "pm list package -e --user \$AUID | cut -f2 -d':' > $LBASE/puser.txt"
  #PKGS="$(pm list packages | cut -f2 -d':')"
  PKGS="`cat $LBASE/pall.txt`"
fi

if [ "$AUID" = "all" ]; then
  #PRE-REQUISITE BEFORE ENTER RECOVERY:
  #  adb shell "pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{' > $LBASE/alluser.txt"
  #AUIDS="$(pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{')"
  AUIDS="`cat $LBASE/alluser.txt`"
fi

for AUID in $AUIDS; do
  echo "Creating backup for AUID $AUID.."
  UPKGS="`cat $LBASE/puser_${AUID}.txt`"
  mkdir -p $LBASE/data/$AUID
  for PKG in $PKGS; do
    #if [ -f /data/app/$PKG-*/base.apk ]; then
    if [ "`$AS \"[ -f /data/app/$PKG-*/base.apk ] && echo 1\"`" ]; then
      echo "  Backing up package $PKG.."
      if [ ! -f "$LBASE/apks/$PKG.apk" ]; then
        printf "    pulling apk.."
		for P in "`$AS ls /data/app/$PKG-*/base.apk | tr -d '\r'`"; do
          $A pull $P $LBASE/apks/$PKG.apk
		done
        echo "    done."
      else
        echo "    $PKG already backed up."
      fi
      #if [ ! -z "$(pm list package -e --user $AUID $PKG)" ]; then
      if [[ "$UPKGS" == *"$PKG"* ]]; then 
        #if [ -d "user/$AUID/$PKG" ]; then
        if [ "`$AS \"[ -d /data/user/$AUID/$PKG ] && echo 1\"`" ]; then
          printf "    backing up userdata.."
          #tar c -C user/$AUID -f $LBASE/data/$AUID/$PKG-user.tar $PKG
          ###$AS "tar c -C /data/user/$AUID $PKG" > $LBASE/data/$AUID/$PKG-user.tar #NOT WORK (EXTRA \r)
          $AS "tar c -C /data/user/$AUID -f /sdcard/$PKG-user.tar $PKG"
          $A pull /sdcard/$PKG-user.tar $LBASE/data/$AUID/
          $AS rm /sdcard/$PKG-user.tar
          #
          echo "    done."
        fi
        #if [ -d "media/$AUID/Android/data/$PKG" ]; then
        if [ "`$AS \"[ -d /data/media/$AUID/Android/data/$PKG ] && echo 1\"`" ]; then
          printf "    backing up media.."
          #tar c -C media/$AUID/Android/data -f $LBASE/data/$AUID/$PKG-media.tar $PKG
          ###$AS "tar c -C /data/media/$AUID/Android/data $PKG" > $LBASE/data/$AUID/$PKG-media.tar #NOT WORK (EXTRA \r)
          $AS "tar c -C /data/media/$AUID/Android/data -f /sdcard/$PKG-media.tar $PKG"
          $A pull /sdcard/$PKG-media.tar $LBASE/data/$AUID/
          $AS rm /sdcard/$PKG-media.tar
          #
          echo "    done."
        fi
      else
        echo "    package $PKG is not enabled for user $AUID"
        touch $LBASE/data/$AUID/$PKG.disabled
      fi
      echo "  done."
    fi
  done
  echo "done."
  #if [ -f "/data/system/users/$AUID/accounts.db" ]; then
  if [ "`$AS \"[ -f /data/system/users/$AUID/accounts.db ] && echo 1 \"`" ] ; then
    printf "Creating backup of accounts.db .."
    #cp /data/system/users/$AUID/accounts.db $LBASE/data/$AUID/
    $A pull /data/system/users/$AUID/accounts.db $LBASE/data/$AUID/
    echo "done."
  fi
done
#if [ -f "/data/system/sync/accounts.xml" ]; then
if [ "`$AS \"[ -f /data/system/sync/accounts.xml ] && echo 1 \"`" ]; then
  printf "Creating backup of accounts.xml .."
  #cp /data/system/sync/accounts.xml $LBASE/data/
  $A pull /data/system/sync/accounts.xml $LBASE/data/
  echo "done."
fi

find $LBASE

echo "Backup complete. Now, please reboot to normal (adb reboot)."
