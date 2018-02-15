#!/sbin/sh
# --------------------------------
# TGPKERNEL INSTALLER 5.0.2
# tgpkernel.sh portion
#
# Created by @djb77 from XDA
# Credit also goes to @Tkkg1994, 
# @lyapota, # @farovitus, 
# @Morogoku, @dwander, and 
# @Chainfire for bits of code
# and/or ideas.
#
# DO NOT USE ANY PORTION OF THIS
# CODE WITHOUT MY PERMISSION!!
# --------------------------------

# Read option number from updater-script
OPTION=$1

# Variables
TGPTEMP=/tmp/tgptemp
AROMA=/tmp/aroma
CONFIG=/data/media/0/TGPKernel/config
KERNELPATH=/tmp/tgptemp/kernels
BUILDPROP=/system/build.prop
remove_list="init.services.rc init.PRIME-Kernel.rc init.spectrum.sh init.spectrum.rc init.primal.rc init.noto.rc kernelinit.sh wakelock.sh super.sh cortexbrain-tune.sh spectrum.sh kernelinit.sh spa init_d.sh initd.sh moro-init.sh sysinit.sh"

if [ $OPTION == "setup" ]; then
	# Set Permissions
	chmod 755 $AROMA/bspatch
	chmod 755 $AROMA/busybox
	chmod 755 $AROMA/tar
	chmod 755 $AROMA/tgpkernel.sh
	# Config Check
	mount /dev/block/platform/11120000.ufs/by-name/USERDATA /data
	# If config backup is present, alert installer
	if [ -e $CONFIG/tgpkernel-backup.prop ]; then
		echo "install=1" > /tmp/aroma/backup.prop
	fi
	# Variant Checks
	getprop ro.boot.bootloader >> /tmp/variant_model
	if grep -q G950F /tmp/variant_model; then
		echo "install=1" > $AROMA/g950x.prop
	fi
	if grep -q G950FD /tmp/variant_model; then
		echo "install=1" > $AROMA/g950x.prop
	fi
	if grep -q G950N /tmp/variant_model; then
		echo "install=1" > $AROMA/g950x.prop
	fi
	if grep -q G955F /tmp/variant_model; then
		echo "install=1" > $AROMA/g955x.prop
	fi
	if grep -q G955FD /tmp/variant_model; then
		echo "install=1" > $AROMA/g955x.prop
	fi
	if grep -q G955N /tmp/variant_model; then
		echo "install=1" > $AROMA/g955x.prop
	fi
	rm -f /tmp/variant_model
	exit 10
fi

if [ $OPTION == "setup_extract" ]; then
	# Extract System Files and Kernels
	cd $TGPTEMP
	tar -Jxf kernels.tar.xz
	if grep -q install=1 $AROMA/check_n8port.prop; then
		tar -Jxf system-tw80.tar.xz
		exit 10
	fi
	if grep -q install=1 $AROMA/check_s9port.prop; then
		tar -Jxf system-tw80-s9port.tar.xz
		exit 10
	fi
	tar -Jxf system-tw7x.tar.xz
	exit 10
fi

if [ $OPTION == "rom_check" ]; then
	# ROM Check
	# Initially set to S8
	echo "install=1" > $AROMA/check_s8.prop
	# Set for Note 8 Ports
	if grep -q ro.build.product=great $BUILDPROP; then
		echo "install=0" > $AROMA/check_s8.prop
		echo "install=1" > $AROMA/check_n8port.prop
	fi
 	# Set for S8 Oreo
 	if grep -q ro.build.version.sdk=26 $BUILDPROP; then
 		echo "install=0" > $AROMA/check_s8.prop
 		echo "install=1" > $AROMA/check_s8oreo.prop
 	fi
	# Set for S9 Ports
	if grep -q ro.build.product=star $BUILDPROP; then
		echo "install=0" > $AROMA/check_s8.prop
 		echo "install=0" > $AROMA/check_s8oreo.prop
		echo "install=1" > $AROMA/check_s9port.prop
	fi
	exit 10
fi

if [ $OPTION == "config_backup" ]; then
	# Backup Config
	# Check if TGP folder exists on Internal Memory, if not, it is created
	if [ ! -d /data/media/0/TGPKernel ]; then
		mkdir /data/media/0/TGPKernel
		chmod 777 /data/media/0/TGPKernel
	fi
	# Check if config folder exists, if it does, delete it 
	if [ -d $CONFIG-backup ]; then
		rm -rf $CONFIG-backup
	fi
	# Check if config folder exists, if it does, ranme to backup
	if [ -d $CONFIG ]; then
		mv -f $CONFIG $CONFIG-backup
	fi
	# Check if config folder exists, if not, it is created
	if [ ! -d $CONFIG ]; then
		mkdir $CONFIG
		chmod 777 $CONFIG
	fi
	# Copy files from /tmp/aroma to backup location
	cp -f /tmp/aroma/* $CONFIG
	# Delete any files from backup that are not .prop files
	find $CONFIG -type f ! -iname "*.prop" -delete
	# Remove unwanted .prop files from the backup
	cd $CONFIG
	[ -f "$CONFIG/check_s8.prop" ] && rm -f $CONFIG/check_s8.prop
	[ -f "$CONFIG/check_n8port.prop" ] && rm -f $CONFIG/check_n8port.prop
	[ -f "$CONFIG/check_s8oreo.prop" ] && rm -f $CONFIG/check_s8oreo.prop
	[ -f "$CONFIG/check_s9port.prop" ] && rm -f $CONFIG/check_s8oreo.prop
	[ -f "$CONFIG/g950x.prop" ] && rm -f $CONFIG/g950x.prop
	[ -f "$CONFIG/g955x.prop" ] && rm -f $CONFIG/g955x.prop
	for delete_prop in *.prop 
	do
		if grep "item" "$delete_prop"; then
			rm -f $delete_prop
		fi
		if grep "install=0" "$delete_prop"; then
			rm -f $delete_prop
		fi 
	done
	exit 10
fi

if [ $OPTION == "config_restore" ]; then
	# Restore Config
	# Copy backed up config files to /tmp/aroma
	cp -f $CONFIG/* $AROMA
	exit 10
fi

if [ $OPTION == "wipe_magisk_supersu" ]; then
	# Wipe SuperSU / Magisk
	rm -rf /data/magisk.apk
	rm -rf /cache/magisk.log /cache/last_magisk.log /cache/magiskhide.log \
		/cache/magisk /cache/magisk_merge /cache/magisk_mount /cache/unblock 2>/dev/null
	rm -rf /data/SuperSU.apk
	rm -rf /data/magisk.log /data/magisk.img /data/magisk_merge.img /data/stock_boot.img \
		/data/busybox /data/magisk /data/custom_ramdisk_patch.sh 2>/dev/null
	rm -rf /data/su.img /data/stock_boot*.gz /data/supersu /supersu /data/adb/su/suhide
	exit 10
fi

if [ $OPTION == "kernel_patch" ]; then
	# Patch Kernel if needed
	cd $KERNELPATH
	if grep -q install=1 $AROMA/g950x.prop; then
		if grep -q install=1 $AROMA/check_s8.prop; then
			cp -f boot.img boot-new.img
			echo "install=1" > $AROMA/flashready.prop
		fi
		if grep -q install=1 $AROMA/check_n8port.prop; then
			$AROMA/bspatch boot.img boot-new.img boot3.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot3.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
		if grep -q install=1 $AROMA/check_s8oreo.prop; then
			$AROMA/bspatch boot.img boot-new.img boot5.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot5.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
		if grep -q install=1 $AROMA/check_s9port.prop; then
			$AROMA/bspatch boot.img boot-new.img boot7.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot7.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
	fi
	if grep -q install=1 $AROMA/g955x.prop; then
		if grep -q install=1 $AROMA/check_s8.prop; then
			$AROMA/bspatch boot.img boot-new.img boot2.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot2.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
		if grep -q install=1 $AROMA/check_n8port.prop; then
			$AROMA/bspatch boot.img boot-new.img boot4.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot4.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
		if grep -q install=1 $AROMA/check_s8oreo.prop; then
			$AROMA/bspatch boot.img boot-new.img boot6.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot6.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
		if grep -q install=1 $AROMA/check_s9port.prop; then
			$AROMA/bspatch boot.img boot-new.img boot8.img.p
			MD5=$($AROMA/busybox md5sum "boot-new.img" | cut -d ' ' -f 1)
			MD5_CHECK=`cat $KERNELPATH/boot8.md5`
			if [ "$MD5" == "$MD5_CHECK" ]; then
				echo "install=1" > $AROMA/flashready.prop
			fi
		fi
	fi
	exit 10
fi

if [ $OPTION == "kernel_flash" ]; then
	# Clean up old kernels (@dwander)
	for i in $remove_list; do
		if test -f $i; then
			[ -f $1 ] && rm -f $i
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/$i/d" init.rc 
			sed -i "/$i/d" init.samsungexynos8890.rc 
		fi
		if test -f sbin/$i; then
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/sbin\/$i/d" init.rc 
			sed -i "/sbin\/$i/d" init.samsungexynos8890.rc 
		fi
	done
	for i in $(ls ./res); do
		test $i != "images" && rm -R ./res/$i
	done
	[ -f /system/bin/uci ] && rm -f /system/bin/uci
	[ -f /system/xbin/uci ] && rm -f /system/xbin/uci
	# Flash Image
	cd $KERNELPATH
	cat boot-new.img > /dev/block/platform/11120000.ufs/by-name/BOOT
	sync
	exit 10
fi

if [ $OPTION == "system_patch" ]; then
	# System Patches
	cd $TGPTEMP
	# Copy system
	cp -rf system/. /system
	# Remove unwanted file from /system/app/mcRegistry
	rm -f /system/app/mcRegistry/ffffffffd0000000000000000000000a.tlbin
	# Remove RMM State Lock
	rm -rf /system/priv-app/Rlc
	sed -i -- 's/ro.security.vaultkeeper.feature=1/ro.security.vaultkeeper.feature=0/g' $BUILDPROP
	# Remove Security Log Agent
	rm -rf /system/app/SecurityLogAgent
	# Remove init.d Placeholder
	rm -f /system/etc/init.d/placeholder
	# ADB
	if grep -q install=1 $AROMA/insecureadb.prop; then
		chown 0:0 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
		chmod 755 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	fi
	exit 10
fi

if [ $OPTION == "splash_flash" ]; then
	# Custom Splash Screen (@Tkkg1994)
	cd /tmp/splash
	mkdir /tmp/splashtmp
	cd /tmp/splashtmp
	$AROMA/tar -xf /dev/block/platform/11120000.ufs/by-name/UP_PARAM
	cp /tmp/splash/logo.jpg .
	chown root:root *
	chmod 444 logo.jpg
	touch *
	$AROMA/tar -pcvf ../new.tar *
	cd ..
	cat new.tar > /dev/block/platform/11120000.ufs/by-name/UP_PARAM
	cd /
	rm -rf /tmp/splashtmp
	rm -f /tmp/new.tar
	sync
	exit 10
fi

if [ $OPTION == "supersu" ]; then
	# SuperSU Script (@Chainfire)
	rm -f /data/.supersu
	rm -f /cache/.supersu
	if [ -f "$AROMA/install.prop" ]; then
		INSTALL=`cat $AROMA/install.prop | grep "selected.0" | cut -f 2 -d '='`
		if [ "$INSTALL" = "2" ]; then
			# System
			echo "SYSTEMLESS=false">>/data/.supersu
		elif [ "$INSTALL" = "3" ]; then
			# Systemless Image
			echo "SYSTEMLESS=true">>/data/.supersu
			echo "BINDSBIN=false">>/data/.supersu
		elif [ "$INSTALL" = "4" ]; then
			# Systemless SBIN
			echo "SYSTEMLESS=true">>/data/.supersu
			echo "BINDSBIN=true">>/data/.supersu
		fi
	fi
	if [ -f "$AROMA/encrypt.prop" ]; then
		KEEPVERITY=`cat $AROMA/encrypt.prop | grep "selected.1" | cut -f 2 -d '='`
		if [ "$KEEPVERITY" = "2" ]; then
			# Remove
			echo "KEEPVERITY=false">>/data/.supersu
		elif [ "$KEEPVERITY" = "3" ]; then
			# Keep
			echo "KEEPVERITY=true">>/data/.supersu
		fi
		KEEPFORCEENCRYPT=`cat $AROMA/encrypt.prop | grep "selected.2" | cut -f 2 -d '='`
		if [ "$KEEPFORCEENCRYPT" = "2" ]; then
			# Remove
			echo "KEEPFORCEENCRYPT=false">>/data/.supersu
		elif [ "$KEEPFORCEENCRYPT" = "3" ]; then
			# Keep
			echo "KEEPFORCEENCRYPT=true">>/data/.supersu
		fi
		REMOVEENCRYPTABLE=`cat $AROMA/encrypt.prop | grep "selected.3" | cut -f 2 -d '='`
		if [ "$REMOVEENCRYPTABLE" = "2" ]; then
			# Remove
			echo "REMOVEENCRYPTABLE=true">>/data/.supersu
		elif [ "$REMOVEENCRYPTABLE" = "3" ]; then
			# Keep
			echo "REMOVEENCRYPTABLE=false">>/data/.supersu
		fi
	fi
	if [ -f "$AROMA/misc.prop" ]; then
		FRP=`cat $AROMA/misc.prop | grep "selected.1" | cut -f 2 -d '='`
		if [ "$FRP" = "2" ]; then
			# Enable
			echo "FRP=true">>/data/.supersu
		elif [ "$FRP" = "3" ]; then
			# Disable
			echo "FRP=false">>/data/.supersu
		fi
		BINDSYSTEMXBIN=`cat $AROMA/misc.prop | grep "selected.2" | cut -f 2 -d '='`
		if [ "$BINDSYSTEMXBIN" = "2" ]; then
			# Enable
			echo "BINDSYSTEMXBIN=true">>/data/.supersu
		elif [ "$BINDSYSTEMXBIN" = "3" ]; then
			# Disable
			echo "BINDSYSTEMXBIN=false">>/data/.supersu
		fi
		PERMISSIVE=`cat $AROMA/misc.prop | grep "selected.3" | cut -f 2 -d '='`
		if [ "$PERMISSIVE" = "2" ]; then
			# Enforcing
			echo "PERMISSIVE=false">>/data/.supersu
		elif [ "$PERMISSIVE" = "3" ]; then
			# Permissive
			echo "PERMISSIVE=true">>/data/.supersu
		fi
	fi
	exit 10
fi

if [ $OPTION == "busybox" ]; then
	# Install Busybox
	mount /dev/block/platform/11120000.ufs/by-name/SYSTEM /system
	cp -f $AROMA/busybox /system/xbin/busybox
	chmod 0755 /system/xbin/busybox
	ln -s /system/xbin/busybox /system/bin/busybox
	/system/xbin/busybox --install -s /system/xbin
	exit 10
fi

if [ $OPTION == "adb" ]; then
	# Install ADB
	cp -rf tmp/adb/* /system/xbin
	chown 0:0 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	chmod 755 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	exit 10
fi

