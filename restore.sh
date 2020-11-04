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

#uid=$1
#shift
#pkg=$1
DEVICE=$1
shift
AUID=$1
shift
PKGS=$*
UPKGS=$PKGS
ALL_PKGS=0

#if [ -z "$uid" -o -z "$pkg" ]; then
if [ -z "$AUID" -o -z "$PKGS" ]; then
  usage
  exit 0
fi

A="$A0 -s $DEVICE"
AS="$A shell"

#base="$devdatadir"
LBASE="$LDATADIR"

#cd /data
#pkgs="$*"
#uids=$uid
AUIDS="$AUID"

$AS mount -a

# Backup all installed packages?
##if [ "$pkg" = "all" ]; then
#if [ "$PKG" = "all" ]; then
#  pkgfiles="$(cd $devdatadir/apks; ls *.apk)"
#  pkgs=""
#  for file in $pkgfiles; do
#    pkgs="$pkgs ${file%\.apk}"
#  done
#fi
if [ "$PKG" = "all" ]; then
  #pkgs="$(pm list packages | cut -f2 -d':')"
  #PRE-REQUISITE BEFORE ENTER RECOVERY:
  #  adb shell "pm list packages | cut -f2 -d':' > $LBASE/pall.txt"
  #  adb shell "pm list package -e --user \$AUID | cut -f2 -d':' > $LBASE/puser.txt"
  #PKGS="$(pm list packages | cut -f2 -d':')"
  PKGS="`cat $LBASE/pall.txt`"
  ALL_PKGS=1
fi

#if [ "$uid" = "all" ]; then
#  uids="$(cd $devdatadir/data; ls | grep '^[0-9]*$')"
#fi
if [ "$AUID" = "all" ]; then
  #PRE-REQUISITE BEFORE ENTER RECOVERY:
  #  adb shell "pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{' > $LBASE/alluser.txt"
  #AUIDS="$(pm list users | grep 'UserInfo' | cut -f1 -d':' | cut -f2 -d'{')"
  AUIDS="`cat $LBASE/alluser.txt`"
fi

#for uid in $uids; do
for AUID in $AUIDS; do
  printf "Restoring backup for uid $uid.."
  if [ $ALL_PKGS -eq 1 ]; then
    UPKGS="`cat $LBASE/puser_$AUID.txt`"
  fi
  #for pkg in $pkgs; do
  for PKG in $UPKGS; do
############# IN NORMAL BOOT #####################
#    #[ -z "$pkg" ] && ( echo "Missing pkg"; exit 1)
#    [ -z "$PKG" ] && ( echo "Missing pkg"; exit 1)
#    echo "  Restoring pkg $PKG.."
#    #if [ -f "$base/apks/$pkg.apk" ]; then
#    if [ -f "$LBASE/apks/$PKG.apk" ]; then
#      #if [ -z "$(pm list package $pkg)" ]; then
#      if [ -z "$(pm list package $PKG)" ]; then
#        echo "    Installing pkg.."
#        #pm install $base/apks/$pkg.apk >/dev/null
#        pm install $base/apks/$PKG.apk >/dev/null
#        echo "    done."
#      else
#        echo "    pkg already installed.."
#      fi
#      #if [ -f "$base/data/$uid/$pkg.disabled" ]; then
#      if [ -f "$LBASE/data/$AUID/$PKG.disabled" ]; then
#        echo "    Disabling pkg.."
#        #pm disable --user $uid $pkg >/dev/null
#        pm disable --user $AUID $PKG >/dev/null
#        echo "    done."
#      else
#        echo "    Enabling pkg.."
#        #pm enable --user $uid $pkg >/dev/null
#        pm enable --user $AUID $PKG >/dev/null
#        echo "    done."
#      fi
#    fi
############### IN RECOVERY #######################
    #if [ -f "$base/data/$uid/$pkg-user.tar" ]; then
    if [ -f "$LBASE/data/$AUID/$PKG-user.tar" ]; then
      printf "    Getting uid/gid and secontext.."
      #secontext=$(ls -dZ user/$uid/$pkg | cut -f1 -d' ')
      SECONTEXT=$($AS "ls -dZ /data/user/$AUID/$PKG" | awk '{ print $1 }')
      if [ "${SECONTEXT:0:1}" != "u" ]; then	#OLD ANDROID
        SECONTEXT=$($AS "ls -dZ /data/user/$AUID/$PKG" | awk '{ print $2 }')
      fi
if [ "${SECONTEXT:0:1}" != "u" ]; then
  echo "SECONTEXT=$SECONTEXT, ls -dZ /data/user/$AUID/$PKG=$($AS ls -dZ /data/user/$AUID/$PKG)"
  exit 1
fi
      #user=$(ls -dl user/$uid/$pkg | cut -f3 -d' ')
      AUSER=$($AS "ls -dl /data/user/$AUID/$PKG" | awk '{ print $3 }')
      #group=$(ls -dl user/$uid/$pkg | cut -f4 -d' ')
      AGROUP=$($AS "ls -dl /data/user/$AUID/$PKG" | awk '{ print $4 }')
      echo "    done."
      printf "    Restoring userdata.."
      #rm -rf user/$uid/$pkg
      $AS rm -rf /data/user/$AUID/$PKG
      #tar x -C user/$uid -f $base/data/$uid/$pkg-user.tar $pkg
      ###cat $LBASE/data/$AUID/$PKG-user.tar | $AS "tar x -C /data/user/$AUID $PKG" &
      $A push $LBASE/data/$AUID/$PKG-user.tar /sdcard/
      $AS "tar x -C /data/user/$AUID -f /sdcard/$PKG-user.tar $PKG"
      $AS "rm /sdcard/$PKG-user.tar"
      #
      echo "    done."
      printf "    Restoring ownership.."
      #chown -R $user:$group user/$uid/$pkg
      $AS "chown -R $AUSER:$AGROUP /data/user/$AUID/$PKG"
      echo "    done."
      printf "    Restoring secontext.."
      #find user/$uid/$pkg -exec chcon $secontext {} \;
      $AS "find /data/user/$AUID/$PKG -exec chcon $SECONTEXT {} \;"
      echo "    done."
    fi
    #if [ -f "$base/data/$uid/$pkg-media.tar" ]; then
    if [ -f "$LBASE/data/$AUID/$PKG-media.tar" ]; then
      printf "    Restoring media.."
      #rm -rf media/$uid/Android/data/$pkg
      $AS "rm -rf /data/media/$AUID/Android/data/$PKG"
      $AS "mkdir -p /data/media/$AUID/Android/data/$PKG"
      #tar x -C media/$uid/Android/data -f $base/data/$uid/$pkg-media.tar $pkg
      ###cat $LBASE/data/$AUID/$PKG-media.tar | $AS "tar x -C /data/media/$AUID/Android/data $PKG"	&
      $A push $LBASE/data/$AUID/$PKG-media.tar /sdcard/
      $AS "tar x -C /data/media/$AUID/Android/data -f /sdcard/$PKG-media.tar $PKG"
      $AS "rm /sdcard/$PKG-media.tar"
      #
      wait
      echo "    done."
    fi
    echo "  done."
  done	#$PKG
  #FIX PERMISSION
  $AS "chown -R media_rw:media_rw /data/media/$AUID"
  $AS "chmod 770 /data/media/$AUID"
  $AS "chmod -R 775 /data/media/$AUID/Android/data"
  echo "done."
done	#$AUID

echo "Restore complete. Now, please reboot to normal (adb reboot)."
