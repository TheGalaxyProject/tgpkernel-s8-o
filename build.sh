#!/bin/bash
# ----------------------------
# TGPKERNEL BUILD SCRIPT 5.5.7
# Created by @djb77
# ----------------------------

# Set Variables
export RDIR=$(pwd)
export KERNELNAME=TGPKernel
export VERSION_NUMBER=$(<build/version)
export ARCH=arm64
export BUILD_CROSS_COMPILE=~/android/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
WORK=.work
WORKDIR=$RDIR/$WORK
ZIPDIR=$RDIR/.work_zip
OUTPUT=$RDIR/.output
OUTDIR=$WORKDIR/arch/$ARCH/boot
KERNELCONFIG=$WORK/arch/arm64/configs/build_defconfig
KEEP=no
SILENT=no
BUILD950=yes
BUILD955=yes

########################################################################################################################################################
# Functions

# Clean Function
FUNC_CLEAN()
{
echo ""
echo "Deleting old work files ..."
echo ""
if [ -d $WORKDIR ]; then
sudo chown 0:0 $WORKDIR 2>/dev/null
sudo chmod -R 777 $WORKDIR
sudo rm -rf $WORKDIR
[ -d "$RDIR/net/wireguard" ] && rm -rf $RDIR/net/wireguard
[ -e "$RDIR/.wireguard-fetch-lock" ] && rm -f $RDIR/.wireguard-fetch-lock
fi
}

# Full clean Function
FUNC_CLEAN_ALL()
{
FUNC_CLEAN
[ -d $ZIPDIR ] && rm -rf $ZIPDIR
[ -d $OUTPUT ] && rm -rf $OUTPUT
exit
}

# Clean ccache
FUNC_CLEAN_CCACHE()
{
echo ""
ccache -C
echo ""
exit
}

# Copy files to work locations
FUNC_COPY()
{
echo "Copying work files ..."
mkdir -p $WORKDIR/arch
mkdir -p $WORKDIR/firmware
mkdir -p $WORKDIR/include
mkdir -p $WORKDIR/net
mkdir -p $WORKDIR/ramdisk/ramdisk
sudo chown 0:0 $WORKDIR/ramdisk/ramdisk 2>/dev/null
mkdir -p $WORKDIR/scripts
cp -rf $RDIR/arch/arm/ $WORKDIR/arch/
cp -rf $RDIR/arch/arm64/ $WORKDIR/arch/
cp -rf $RDIR/arch/x86 $WORKDIR/arch/
cp -rf $RDIR/firmware $WORKDIR/
cp -rf $RDIR/include $WORKDIR/
cp -rf $RDIR/net $WORKDIR/
cp -rf $RDIR/build/aik/* $WORKDIR/ramdisk
cp -rf $RDIR/scripts $WORKDIR/
sudo cp -rf $RDIR/build/ramdisk/* $WORKDIR/ramdisk 
}

# Build zimage Function
FUNC_BUILD_KERNEL()
{
echo "Preparing configuration ..."
cp -f $WORKDIR/arch/arm64/configs/tgpkernel_defconfig $KERNELCONFIG
[ $MODEL = "S8" ] && cat $WORKDIR/arch/arm64/configs/dreamlte_defconfig >> $KERNELCONFIG
[ $MODEL = "S8+" ] && cat $WORKDIR/arch/arm64/configs/dream2lte_defconfig >> $KERNELCONFIG
cd $WORKDIR
sudo find . -name \.placeholder -type f -delete
cd $RDIR
echo "Loading configuration ..."
echo ""
if [ $SILENT = "no" ]; then
	make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
else
	make -s -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
fi
echo "Compiling zImage and dtb ..."
echo ""
if [ $SILENT = "no" ]; then
	make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
else
	make -s -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
fi
echo ""
echo "Compiling Ramdisk ..."
sudo cp $WORKDIR/arch/$ARCH/boot/Image $WORKDIR/ramdisk/split_img/boot.img-zImage
sudo cp $WORKDIR/arch/$ARCH/boot/dtb.img $WORKDIR/ramdisk/split_img/boot.img-dtb
if [ $MODEL = "S8" ]; then
	sudo sed -i -- 's/G955/G950/g' $WORKDIR/ramdisk/ramdisk/default.prop
	sudo sed -i -- 's/dream2lte/dreamlte/g' $WORKDIR/ramdisk/ramdisk/default.prop
	sudo sed -i -- 's/SRPPH16A003KU/SRPPK02A003KU/g' $WORKDIR/ramdisk/split_img/boot.img-board
fi
	cd $WORKDIR/ramdisk
	./repackimg.sh
echo ""
}

# Build boot.img Function
FUNC_BUILD_BOOTIMG()
{
	(
	FUNC_CLEAN
	FUNC_COPY
	FUNC_BUILD_KERNEL
	) 2>&1	 | tee -a $LOGFILE
}

# Build config files seperately
FUNC_CONFIGS()
{
# Config for S8
MODEL=S8
FUNC_CLEAN
FUNC_COPY
KERNELCONFIG=$WORK/arch/arm64/configs/exynos8895-dreamlte_defconfig
make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
mv -f $WORKDIR/.config $RDIR/arch/arm64/configs/exynos8895-dreamlte_defconfig
# Config for S8+
MODEL=S8+
FUNC_CLEAN
FUNC_COPY
KERNELCONFIG=$WORK/arch/arm64/configs/exynos8895-dream2lte_defconfig
make -C $RDIR O=$WORK -j$BUILD_JOB_NUMBER ARCH=$ARCH CROSS_COMPILE=$BUILD_CROSS_COMPILE ../../../$KERNELCONFIG || exit -1
mv -f $WORKDIR/.config $RDIR/arch/arm64/configs/exynos8895-dream2lte_defconfig
# Clean up
FUNC_CLEAN
exit
}

# Build Zip Function
FUNC_BUILD_ZIP()
{
echo "Preparing Zip File  ..."
echo ""
echo "- Building anykernel2.zip file ..."
cd $ZIPDIR/tgpkernel/anykernel2
rm -f $ZIPDIR/tgpkernel/anykernel2/.git.zip
[ -d $ZIPDIR/tgpkernel/anykernel2/.git ] && rm -rf $ZIPDIR/tgpkernel/anykernel2/.git
zip -9gq anykernel2.zip -r * -x "*~"
if [ -n `which java` ]; then
	echo "  Java detected, signing zip"
	AK2_NAME=anykernel2.zip
	mv $AK2_NAME unsigned-$AK2_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 unsigned-$AK2_NAME $AK2_NAME
	rm unsigned-$AK2_NAME
fi
echo "  Deleting unwanted files"
rm -rf META-INF tgpkernel patch tools anykernel.sh README.md
echo "- Building system.tar.xz file ..."
cd $ZIPDIR/tgpkernel
tar -cf - system/ | xz -9 -c - > system.tar.xz
mv -f system.tar.xz $ZIPDIR/tgpkernel/files/system.tar.xz
rm -rf $ZIPDIR/tgpkernel/system
echo "- Building kernels.tar.xz file ..."
tar -cf - kernels/ | xz -9 -c - > kernels.tar.xz
mv -f kernels.tar.xz $ZIPDIR/tgpkernel/files/kernels.tar.xz
rm -rf $ZIPDIR/tgpkernel/kernels
echo "- Building final zip ..."
cd $ZIPDIR
zip -9gq $ZIP_NAME -r META-INF/ -x "*~"
zip -9gq $ZIP_NAME -r tgpkernel/ -x "*~" 
if [ -n `which java` ]; then
	echo "  Java detected, signing zip"
	mv $ZIP_NAME unsigned-$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 unsigned-$ZIP_NAME $ZIP_NAME
	rm unsigned-$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $OUTPUT/$ZIP_NAME
cd $RDIR
}

########################################################################################################################################################
# Main script

# Check command line for switches
[ "$1" = "0" ] && FUNC_CLEAN_ALL
[ "$1" = "00" ] && FUNC_CLEAN_CCACHE
[ "$1" = "configs" ] && FUNC_CONFIGS
[ "$1" = "950" ] || [ "$2" = "950" ] || [ "$3" = "950" ] || [ "$4" = "950" ] && export BUILD955=no
[ "$1" = "955" ] || [ "$2" = "955" ] || [ "$3" = "955" ] || [ "$4" = "955" ] && export BUILD950=no
[ "$1" = "-ks" ] || [ "$2" = "-ks" ] || [ "$3" = "-ks" ] || [ "$4" = "-ks" ] && export SILENT=yes && export KEEP=yes
[ "$1" = "-k" ] || [ "$2" = "-k" ] || [ "$3" = "-k" ] || [ "$4" = "-k" ] && export KEEP=yes
[ "$1" = "-s" ] || [ "$2" = "-s" ] || [ "$3" = "-s" ] || [ "$4" = "-s" ] && export SILENT=yes

# Start Script
clear
echo ""
echo "+-----------------------------------------+"
echo "-                                         -"
echo "-     @@@@@@@@@@    @@@@@  @@@@@@@@       -"
echo "-     @@@@@@@@@@ @@@@@@@@@ @@@@@@@@@@     -"
echo "-        @@@@  '@@@@@@@@@@ @@@@@@@@@@     -"
echo "-        @@@@   @@@@@@@     @@@   @@@     -"
echo "-        @@@@   @@@@@       @@@  @@@@     -"
echo "-        @@@@   @@@@@  @@@@ @@@@@@@@      -"
echo "-        @@@@    @@@@@ @@@@ @@@@@@@       -"
echo "-        @@@@    @@@@@@@@@@ @@@@          -"
echo "-        @@@@     @@@@@@@@ @@@@@          -"
echo "-                    @@@@@                -"
echo "-                                         -"
echo "-     TGPKernel Build Script by djb77     -"
echo "-                                         -"
echo "+-----------------------------------------+"
echo ""
sudo echo ""
[ -d "$WORKDIR" ] && rm -rf $WORKDIR
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ -d "$OUTPUT" ] && rm -rf $OUTPUT
[ -d "$RDIR/net/wireguard" ] && rm -rf $RDIR/net/wireguard
mkdir $ZIPDIR
mkdir $OUTPUT
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels

START_TIME=`date +%s`

# Build S8 img files
if [ $BUILD950 = "yes" ]; then
	MODEL=S8
	echo "---------------------"
	echo "Building S8 .img file"
	echo "---------------------"
	export KERNELTITLE=$KERNELNAME.$MODEL.$VERSION_NUMBER
	LOGFILE=$OUTPUT/build-s8.log
	FUNC_BUILD_BOOTIMG
	mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot-s8.img
fi
if [ $BUILD955 = "yes" ]; then
	MODEL=S8+
	echo "----------------------"
	echo "Building S8+ .img file"
	echo "----------------------"
	export KERNELTITLE=$KERNELNAME.$MODEL.$VERSION_NUMBER
	LOGFILE=$OUTPUT/build-s8+.log
	FUNC_BUILD_BOOTIMG
	mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot-s8+.img
fi

# Final archiving
echo ""
echo "---------------"
echo "Final archiving"
echo "---------------"
echo ""
if [ $KEEP = "yes" ]; then
	echo "Copying .img files to output folder ..."
	cp -f $ZIPDIR/tgpkernel/kernels/boot-s8.img $OUTPUT/boot-s8.img
	cp -f $ZIPDIR/tgpkernel/kernels/boot-s8+.img $OUTPUT/boot-s8+.img
	echo ""
fi
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G95xx.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
FUNC_CLEAN
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo "You will find your logs and files in the .output folder"
echo ""
[ -d "$RDIR/net/wireguard" ] && rm -rf $RDIR/net/wireguard
exit

