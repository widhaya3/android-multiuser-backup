#!/bin/bash
#*** RUN IN LINUX SHELL ***

. $(dirname $0)/config

function usage {
	echo "usage: $0 DEVICE USER_ID|all PACKAGES...|all"
	echo "exam1: $0 XXXXXXXXXXXXXXXX all all"
	echo "exam2: $0 XXXXXXXXXXXXXXXX 0 com.google.android.youtube"
	echo "step: adb-restore.sh -> reboot recovery (or rooted) -> restore.sh"
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
START_AUID=$AUID
shift
PKG=$1
START_PKG=$PKG

#if [ -z "$uid" -o -z "$pkg" ]; then
if [ -z "$DEVICE" -o -z "$AUID" -o -z "$PKG" ]; then
  echo "Usage $0 <DEVICE> <AUID> <PKG>"
  exit 0
fi

A="$A0 -s $DEVICE"
AS="$A shell"

#base="$devdatadir"
LBASE="$LDATADIR"

#cd /data
#pkgs="$*"
#uids=$uid
PKGS="$*"
AUIDS="$AUID"

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
  UPKGS="`cat $LBASE/puser_$AUID.txt`"
  #for pkg in $pkgs; do
  for PKG in $UPKGS; do
    #[ -z "$pkg" ] && ( echo "Missing pkg"; exit 1)
    [ -z "$PKG" ] && ( echo "Missing pkg"; exit 1)
    printf "  Restoring pkg $PKG.."
    #if [ -f "$base/apks/$pkg.apk" ]; then
    if [ -f "$LBASE/apks/$PKG.apk" ]; then
      #if [ -z "$(pm list package $pkg)" ]; then
      if [ -z "$($AS pm list package $PKG)" ]; then
        printf "    Installing pkg.."
        #pm install $base/apks/$pkg.apk >/dev/null
        $A install $LBASE/apks/$PKG.apk >/dev/null
        echo "    done."
      else
        echo "    pkg already installed.."
      fi
      #if [ -f "$base/data/$uid/$pkg.disabled" ]; then
      if [ -f "$LBASE/data/$AUID/$PKG.disabled" ]; then
        printf "    Disabling pkg.."
        #pm disable --user $uid $pkg >/dev/null
        $AS pm disable --user $AUID $PKG >/dev/null
        echo "    done."
      else
        printf "    Enabling pkg.."
        #pm enable --user $uid $pkg >/dev/null
        $AS pm enable --user $AUID $PKG >/dev/null
        echo "    done."
      fi
    fi
############### IN RECOVERY #######################
#    #if [ -f "$base/data/$uid/$pkg-user.tar" ]; then
#    if [ -f "$LBASE/data/$AUID/$PKG-user.tar" ]; then
#      echo "    Getting uid/gid and secontext.."
#      #secontext=$(ls -dZ user/$uid/$pkg | cut -f1 -d' ')
#      SECONTEXT=$(ls -dZ /data/user/$AUID/$PKG | cut -f1 -d' ')
#      #user=$(ls -dl user/$uid/$pkg | cut -f3 -d' ')
#      AUSERr=$(ls -dl /data/user/$AUID/$PKG | cut -f3 -d' ')
#      #group=$(ls -dl user/$uid/$pkg | cut -f4 -d' ')
#      AGROUP=$(ls -dl /data/user/$AUID/$PKG | cut -f4 -d' ')
#      echo "    done."
#      echo "    Restoring userdata.."
#      #rm -rf user/$uid/$pkg
#      rm -rf /data/user/$UID/$PKG
#      #tar x -C user/$uid -f $base/data/$uid/$pkg-user.tar $pkg
#      cat $LBASE/data/$AUID/$PKG-user.tar | $AS "tar x -C user/$AUID $PKG"
#      echo "    done."
#      echo "    Restoring ownership.."
#      #chown -R $user:$group user/$uid/$pkg
#      $AS "chown -R $AUSER:$AGROUP user/$AUID/$PKG"
#      echo "    done."
#      echo "    Restoring secontext.."
#      #find user/$uid/$pkg -exec chcon $secontext {} \;
#      $AS "find user/$AUID/$PKG -exec chcon $SECONTEXT {} \;"
#      echo "    done."
#    fi
#    #if [ -f "$base/data/$uid/$pkg-media.tar" ]; then
#    if [ -f "$LBASE/data/$AUID/$PKG-media.tar" ]; then
#      echo "    Restoring media.."
#      #rm -rf media/$uid/Android/data/$pkg
#      $AS "rm -rf /datamedia/$AUID/Android/data/$PKG"
#      #tar x -C media/$uid/Android/data -f $base/data/$uid/$pkg-media.tar $pkg
#      cat $LBASE/data/$AUID/$PKG-media.tar | $AS "tar x -C media/$AUID/Android/data $PKG"
#      echo "    done."
#    fi
    echo "  done."
  done
  echo "done."
done

echo "Next, reboot to recovery to restore userdata (adb reboot recovery, adb reboot bootloader && fastboot boot twrp-xxxx)"
echo "Then run: $(dirname $0)/restore.sh $DEVICE $START_AUID $START_PKG"
