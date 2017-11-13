# -------------------------------
# TGPKERNEL AROMA INSTALLER 5.0.2
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
if egrep -q "install=0" "/tmp/aroma/check_s8.prop"; then
insert_line init.rc "import /init.services.rc" after "import /init.fac.rc" "import /init.services.rc"
fi
if egrep -q "install=1" "/tmp/aroma/check_s8oreo.prop"; then
insert_line init.rc "import /init.services.rc" after "import /init.container.rc" "import /init.services.rc"
fi
if egrep -q "install=1" "/tmp/aroma/check_s9port.prop"; then
insert_line init.rc "import /init.services.rc" after "import /init.container.rc" "import /init.services.rc"
fi

# Ramdisk changes - SELinux Enforcing Mode
if egrep -q "install=1" "/tmp/aroma/selinux.prop"; then
	ui_print "- Enabling SELinux Enforcing Mode"
	replace_string sbin/kernelinit.sh "echo \"1\" > /sys/fs/selinux/enforce" "echo \"0\" > /sys/fs/selinux/enforce" "echo \"1\" > /sys/fs/selinux/enforce"
	replace_string sbin/kernelinit.sh "chmod 644 /sys/fs/selinux/enforce" "chmod 640 /sys/fs/selinux/enforce" "chmod 644 /sys/fs/selinux/enforce"
	replace_string sbin/kernelinit.sh "setenforce 1" "setenforce 0" "setenforce 1"
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
chmod 755 $ramdisk/sbin/kernelinit.sh
chown -R root:root $ramdisk/*

# End ramdisk changes
ui_print "- Writing Boot Image"
write_boot

## End install
ui_print "- Done"

