#!/sbin/sh
# Variant check script by djb77
# Inspired by Tkkg1994

# BOOTLOADER CHECKS
# -----------------
getprop ro.boot.bootloader >> /tmp/variant_model
if grep -q G950F /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g950x.prop
fi
if grep -q G950FD /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g950x.prop
fi
if grep -q G950N /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g950x.prop
fi
if grep -q G955F /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g955x.prop
fi
if grep -q G955FD /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g955x.prop
fi
if grep -q G955N /tmp/variant_model;
then
	echo "install=1" > /tmp/aroma/g955x.prop
fi

exit 10

