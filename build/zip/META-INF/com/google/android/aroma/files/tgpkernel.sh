#!/sbin/sh
# ------------------------------
# TGPKERNEL INSTALLER 5.5.7
# Created by @djb77
#
# Credit also goes to @Tkkg1994,
# @lyapota, @Morogoku and 
# @dwander for bits of code
# ------------------------------

# Read option number from updater-script
OPTION=$1

# Block location
BLOCK=/dev/block/platform/11120000.ufs/by-name

# Variables
TGPTEMP=/tmp/tgptemp
AROMA=/tmp/aroma
TGP=/data/media/0/TGPKernel
CONFIG=$TGP/config
KERNELPATH=$TGPTEMP/kernels
BUILDPROP=/system/build.prop
KERNEL_REMOVE="init.services.rc init.PRIME-Kernel.rc init.spectrum.sh init.spectrum.rc init.primal.rc init.noto.rc kernelinit.sh wakelock.sh super.sh cortexbrain-tune.sh spectrum.sh kernelinit.sh spa init_d.sh initd.sh moro-init.sh sysinit.sh tgpkernel.sh noto.sh"

if [ $OPTION == "setup" ]; then
	## Set Permissions
	chmod 755 $AROMA/tar
	chmod 755 $AROMA/tgpkernel.sh
	exit 10
fi

if [ $OPTION == "config_check" ]; then
	## Config Check
	# If config backup is present, alert installer
	mount $BLOCK/USERDATA /data
	if [ -e $CONFIG/tgpkernel-backup.prop ]; then
		echo "install=1" > $AROMA/backup.prop
	fi
	exit 10
fi

if [ $OPTION == "variant_check" ]; then
	## Variant Checks
	getprop ro.boot.bootloader >> /tmp/variant_model
	if grep -q G950 /tmp/variant_model; then
		echo "install=1" > $AROMA/g950x.prop
	fi
	if grep -q G955 /tmp/variant_model; then
		echo "install=1" > $AROMA/g955x.prop
	fi
	rm -f /tmp/variant_model
	exit 10
fi

if [ $OPTION == "setup_extract" ]; then
	## Extract System Files and Kernels
	cd $TGPTEMP
	tar -Jxf kernels.tar.xz
	tar -Jxf system.tar.xz
	exit 10
fi

if [ $OPTION == "rom_check" ]; then
	## ROM Check
	# Initially set to S8
	echo "install=1" > $AROMA/check_s8.prop
	# Check for Deodexed ROMs
	if [ ! -d /system/framework/arm64 ]; then
		echo "install=1" > $AROMA/deodexed.prop
		echo "install=1" > $AROMA/anykernel.prop
	fi
	# Set for S9 Ports
	if grep -q ro.build.product=star $BUILDPROP; then
		echo "install=0" > $AROMA/check_s8.prop
		echo "install=1" > $AROMA/check_s9port.prop
	fi
	# Set for N8 Oreo Ports
	if grep -q ro.build.product=great $BUILDPROP; then
		if grep -q ro.build.version.release=8.0.0 $BUILDPROP; then
		echo "install=0" > $AROMA/check_s8.prop
			echo "install=0" > $AROMA/check_s9port.prop
			echo "install=1" > $AROMA/check_n8port.prop
		fi
	fi
	exit 10
fi

if [ $OPTION == "config_backup" ]; then
	## Backup Config
	# Check if TGP folder exists on Internal Memory, if not, it is created
	if [ ! -d $TGP ]; then
		mkdir $TGP
		chmod 777 $TGP
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
	# Copy files from $AROMA to backup location
	cp -f $AROMA/* $CONFIG
	# Delete any files from backup that are not .prop files
	find $CONFIG -type f ! -iname "*.prop" -delete
	# Remove unwanted .prop files from the backup
	cd $CONFIG
	[ -f "$CONFIG/check_s8.prop" ] && rm -f $CONFIG/check_s8.prop
	[ -f "$CONFIG/check_n8port.prop" ] && rm -f $CONFIG/check_n8port.prop
	[ -f "$CONFIG/check_s9port.prop" ] && rm -f $CONFIG/check_s9port.prop
	[ -f "$CONFIG/deodexed.prop" ] && rm -f $CONFIG/deodexed.prop
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
	## Restore Config
	# Copy backed up config files to $AROMA
	cp -f $CONFIG/* $AROMA
	exit 10
fi

if [ $OPTION == "wipe_magisk" ]; then
	## Wipe old Magisk / SuperSU Installs
	mount /cache
	rm -rf /system/.pin /system/bin/.ext /system/etc/.installed_su_daemon /system/etc/.has_su_daemon \
	/system/xbin/daemonsu /system/xbin/su /system/xbin/sugote /system/xbin/sugote-mksh /system/xbin/supolicy \
	/system/bin/app_process_init /system/bin/su /cache/su /system/lib/libsupol.so /system/lib64/libsupol.so \
	/system/su.d /system/etc/install-recovery.sh /system/etc/init.d/99SuperSUDaemon /cache/install-recovery.sh \
	/system/.supersu /cache/.supersu /data/.supersu \
	/system/app/Superuser.apk /system/app/SuperSU /cache/Superuser.apk \
	/cache/.supersu /cache/su.img /cache/SuperSU.apk \
	/data/.supersu /data/stock_boot_*.img.gz /data/su.img \
	/data/SuperSU.apk /data/app/eu.chainfire.supersu* \
	/data/data/eu.chainfire.supersu /data/supersu /supersu  2>/dev/null
	exit 10
fi

if [ $OPTION == "system_patch" ]; then
	## System Patches
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
	# Delete Wakelock.sh 
	rm -f /magisk/phh/su.d/wakelock*
	rm -f /su/su.d/wakelock*
	rm -f /system/su.d/wakelock*
	rm -f /system/etc/init.d/wakelock*
	exit 10
fi

if [ $OPTION == "kernel_flash" ]; then
	## Flash Kernel (@dwander)
	# Clean up old kernels
	for i in $KERNEL_REMOVE; do
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
	[ -d /sbin/.backup ] && rm -rf /sbin/.backup
	[ -f /system/bin/uci ] && rm -f /system/bin/uci
	[ -f /system/xbin/uci ] && rm -f /system/xbin/uci
	# Flash new Image
	if grep -q install=1 $AROMA/g950x.prop; then
		dd if=$KERNELPATH/boot-s8.img of=$BLOCK/BOOT
	fi
	if grep -q install=1 $AROMA/g955x.prop; then
		dd if=$KERNELPATH/boot-s8+.img of=$BLOCK/BOOT
	fi
	sync
	exit 10
fi

if [ $OPTION == "splash_flash" ]; then
	## Custom Splash Screen (@Tkkg1994)
	cd /tmp/splash
	mkdir /tmp/splashtmp
	cd /tmp/splashtmp
	$AROMA/tar -xf $BLOCK/UP_PARAM
	cp /tmp/splash/logo.jpg .
	chown root:root *
	chmod 444 logo.jpg
	touch *
	$AROMA/tar -pcvf ../new.tar *
	cd ..
	cat new.tar > $BLOCK/UP_PARAM
	cd /
	rm -rf /tmp/splashtmp
	rm -f /tmp/new.tar
	sync
	exit 10
fi

