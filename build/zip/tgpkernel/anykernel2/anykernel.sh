# -------------------------------
# TGPKERNEL AROMA INSTALLER 3.2.0
# anykernel2 portion
#
# Anykernel2 created by #osm0sis
# Everything else done by @djb77
#
# DO NOT USE ANY PORTION OF THIS
# CODE WITHOUT MY PERMISSION!!
# -------------------------------

## AnyKernel setup
properties() {
kernel.string=
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=dreamlte
device.name2=dream2lte
device.name3=
device.name4=
device.name5=
}

# Shell Variables
block=/dev/block/platform/11120000.ufs/by-name/BOOT
ramdisk=/tmp/anykernel/ramdisk
split_img=/tmp/anykernel/split_img
patch=/tmp/anykernel/patch
is_slot_device=0
ramdisk_compression=auto

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh

## AnyKernel install
ui_print "- Extracing Boot Image"
dump_boot

# Ramdisk changes - New Files
ui_print "- Adding TGPKernel Mods"
cp -rf $patch/mods/* $ramdisk
chmod 755 $ramdisk/sbin/initd.sh
chmod 755 $ramdisk/sbin/kernelinit.sh
chmod 755 $ramdisk/sbin/resetprop
chmod 755 $ramdisk/sbin/wakelock.sh
chmod 755 $ramdisk/init.services.rc
insert_line init.rc "import /init.services.rc" after "import /init.fac.rc" "import /init.services.rc"

# Ramdisk changes - Insecure ADB
if egrep -q "install=1" "/tmp/aroma/insecureadb.prop"; then
	ui_print "- Enabling Insecure ADB"
	replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0"
	cp -rf $patch/adbd/* $ramdisk/sbin
	chmod 755 $ramdisk/sbin/adbd
fi

# Ramdisk changes - Spectrum
if egrep -q "install=1" "/tmp/aroma/spectrum.prop"; then
	ui_print "- Adding Spectrum"
	cp -rf $patch/spectrum/* $ramdisk
	chmod 644 $ramdisk/init.spectrum.rc
	chmod 644 $ramdisk/init.spectrum.sh
	insert_line init.rc "import /init.spectrum.rc" after "import /init.services.rc" "import /init.spectrum.rc"
fi

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod 644 $ramdisk/default.prop
chmod 755 $ramdisk/init.rc
chown -R root:root $ramdisk/*

# End ramdisk changes
ui_print "- Writing Boot Image"
write_boot

## End install
ui_print "- Done"

