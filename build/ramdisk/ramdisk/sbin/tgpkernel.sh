#!/system/bin/sh

# Set Variables
RESETPROP="/sbin/magisk resetprop -v -n"

# Mount
mount -o remount,rw -t auto /
mount -t rootfs -o remount,rw rootfs
mount -o remount,rw -t auto /system
mount -o remount,rw /data
mount -o remount,rw /cache

# Set KNOX to 0x0 on running /system
$RESETPROP ro.boot.warranty_bit "0"
$RESETPROP ro.warranty_bit "0"

# Fix Samsung Related Flags
$RESETPROP ro.fmp_config "1"
$RESETPROP ro.boot.fmp_config "1"

# Fix safetynet flags
$RESETPROP ro.boot.veritymode "enforcing"
$RESETPROP ro.boot.verifiedbootstate "green"
$RESETPROP ro.boot.flash.locked "1"
$RESETPROP ro.boot.ddrinfo "00000001"

# SELinux (0 / 640 = Permissive, 1 / 644 = Enforcing)
echo "0" > /sys/fs/selinux/enforce
chmod 640 /sys/fs/selinux/enforce

# Google play services wakelock fix (@Tkkg1994)
sleep 1
su -c "pm enable com.google.android.gms/.update.SystemUpdateActivity"
su -c "pm enable com.google.android.gms/.update.SystemUpdateService"
su -c "pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver"
su -c "pm enable com.google.android.gms/.update.SystemUpdateService$Receiver"
su -c "pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver"
su -c "pm enable com.google.android.gsf/.update.SystemUpdateActivity"
su -c "pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity"
su -c "pm enable com.google.android.gsf/.update.SystemUpdateService"
su -c "pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver"
su -c "pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver"

# init.d
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d
fi
chown -R root.root /system/etc/init.d
chmod -R 755 /system/etc/init.d
for FILE in /system/etc/init.d/*; do
	sh $FILE >/dev/null
done;

# Deepsleep fix (@Chainfire)
for i in `ls /sys/class/scsi_disk/`; do
	cat /sys/class/scsi_disk/$i/write_protect 2>/dev/null | grep 1 >/dev/null
	if [ $? -eq 0 ]; then
		echo 'temporary none' > /sys/class/scsi_disk/$i/cache_type
	fi
done

# Fix personalist.xml
if [ ! -f /data/system/users/0/personalist.xml ]; then
	touch /data/system/users/0/personalist.xml
	chmod 600 /data/system/users/0/personalist.xml
	chown system:system /data/system/users/0/personalist.xml
fi

# Unmount
mount -o remount,ro -t auto /
mount -t rootfs -o remount,ro rootfs
mount -o remount,ro -t auto /system
mount -o remount,rw /data
mount -o remount,rw /cache

