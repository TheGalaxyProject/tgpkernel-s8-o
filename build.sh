#!/bin/bash
# ----------------------------
# TGPKERNEL BUILD SCRIPT 4.3.0
# Created by djb77 from XDA
#
# DO NOT USE ANY PORTION OF
# THIS CODE WITHOUT MY
# PERMISSION!! Thank you :)
# ----------------------------

# Set Variables
export RDIR=$(pwd)
export VERSION_NUMBER=$(<build/version)
export ARCH=arm64
export BUILD_CROSS_COMPILE=~/android/toolchains/aarch64-cortex_a53-linux-gnueabi/bin/aarch64-cortex_a53-linux-gnueabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export WORKDIR=$RDIR/.work
ZIPDIR=$RDIR/.work_zip
OUTPUT=$RDIR/output
OUTDIR=$WORKDIR/arch/$ARCH/boot
DTSDIR=$WORKDIR/arch/$ARCH/boot/dts/exynos
DTBDIR=$WORKDIR/arch/$ARCH/boot/dtb
DTCTOOL=$WORKDIR/scripts/dtc/dtc
INCDIR=$WORKDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELCONFIG=tgpkernel
KERNELNAME=TGPKernel
KEEP=no
SILENT=no
S8=0
N8PORT=0

# Clean Function
FUNC_CLEAN()
{
echo ""
echo "Deleting old work files ..."
echo ""
if [ -d "$WORKDIR" ]; then
sudo chown 0:0 $WORKDIR 2>/dev/null
sudo chmod -R 777 $WORKDIR
sudo rm -rf $WORKDIR
fi
}

# Full clean Function
OPTION_CLEAN_ALL()
{
FUNC_CLEAN
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ -d "$RDIR/.build" ] && rm -rf $RDIR/.build
[ -d "$OUTPUT" ] && rm -rf $OUTPUT
[ -d "$RDIR/net" ] && rm -rf $RDIR/net
exit
}

# Clean ccache
OPTION_CCACHE()
{
ccache -C
exit
}

# Check command line for switches
if [ "$1" == "0" ]; then
	OPTION_CLEAN_ALL
fi
if [ "$1" == "00" ]; then
	OPTION_CCACHE
fi
if [ "$1" == "keep" ]; then
	KEEP=yes
fi
if [ "$1" == "silent" ]; then
	SILENT=yes
fi
if [ "$2" == "keep" ]; then
	KEEP=yes
fi
if [ "$2" == "silent" ]; then
	SILENT=yes
fi

# Build zimage Function
FUNC_COPY()
{
echo "Copying work files ..."
echo ""
mkdir -p $WORKDIR/arch
mkdir -p $WORKDIR/firmware
mkdir -p $WORKDIR/include
mkdir -p $WORKDIR/net
mkdir -p $WORKDIR/ramdisk/ramdisk
mkdir -p $WORKDIR/ramdisk/ramdisk/config
chmod 500 $WORKDIR/ramdisk/ramdisk/config
mkdir -p $WORKDIR/scripts
cp -rf $RDIR/arch/arm/ $WORKDIR/arch/
cp -rf $RDIR/arch/arm64/ $WORKDIR/arch/
cp -rf $RDIR/arch/x86 $WORKDIR/arch/
cp -rf $RDIR/firmware $WORKDIR/
cp -rf $RDIR/include $WORKDIR/
cp -rf $RDIR/net $WORKDIR/
cp -rf $RDIR/.build/aik/* $WORKDIR/ramdisk
cp -rf $RDIR/scripts $WORKDIR/
if [ $S8 == "1" ]; then
	cp -rf $RDIR/.build/ramdisk-s8/* $WORKDIR/ramdisk 
fi
if [ $N8PORT == "1" ]; then
	cp -rf $RDIR/.build/ramdisk-n8port/* $WORKDIR/ramdisk 
fi
sudo chown -R 0:0 $WORKDIR/ramdisk/ramdisk
sudo chown -R 0:0 $WORKDIR/ramdisk/split_img
}

# Build zimage Function
FUNC_BUILD_ZIMAGE()
{
cd $WORKDIR
sudo find . -name \.placeholder -type f -delete
cd ..
if [ $SILENT = "no" ]; then
	echo "Loading configuration ..."
	echo ""
	make -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE \
		$KERNEL_DEFCONFIG || exit -1
	echo ""
	echo "Compiling zImage ..."
	echo ""
	make -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""
else
	echo "Loading configuration ..."
	echo ""
	make -s -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE \
		$KERNEL_DEFCONFIG || exit -1
	echo ""
	echo "Compiling zImage ..."
	echo ""
	make -s -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
		CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""
fi
}

# Build DTB Function
FUNC_BUILD_DTB()
{
if [ $MODEL = "dreamlte" ]; then
	DTSFILES="exynos8895-dreamlte_eur_open_00 exynos8895-dreamlte_eur_open_01
		exynos8895-dreamlte_eur_open_02 exynos8895-dreamlte_eur_open_03
		exynos8895-dreamlte_eur_open_04 exynos8895-dreamlte_eur_open_05
		exynos8895-dreamlte_eur_open_07 exynos8895-dreamlte_eur_open_08
		exynos8895-dreamlte_eur_open_09 exynos8895-dreamlte_eur_open_10"
else
	DTSFILES="exynos8895-dream2lte_eur_open_01 exynos8895-dream2lte_eur_open_02
		exynos8895-dream2lte_eur_open_03 exynos8895-dream2lte_eur_open_04
		exynos8895-dream2lte_eur_open_05 exynos8895-dream2lte_eur_open_06
		exynos8895-dream2lte_eur_open_07 exynos8895-dream2lte_eur_open_08
		exynos8895-dream2lte_eur_open_09 exynos8895-dream2lte_eur_open_10"
fi
mkdir -p $OUTDIR $DTBDIR
cd $DTBDIR
rm -f ./*
echo ""
echo "Processing DTS files ..."
echo ""
for dts in $DTSFILES; do
	echo "Processing: ${dts}.dts"
	${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
	echo "Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
done
echo ""
echo "Generating dtb.img"
echo ""
$WORKDIR/scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
}

# Build Ramdisk Function
FUNC_BUILD_RAMDISK()
{
sudo mv $WORKDIR/arch/$ARCH/boot/Image $WORKDIR/ramdisk/split_img/boot.img-zImage
sudo mv $WORKDIR/arch/$ARCH/boot/dtb.img $WORKDIR/ramdisk/split_img/boot.img-dtb
if [ $MODEL = "dreamlte" ]; then
	sudo sed -i -- 's/G955/G950/g' $WORKDIR/ramdisk/ramdisk/default.prop
	sudo sed -i -- 's/SRPPH16A001KU/SRPPK02A001KU/g' $WORKDIR/ramdisk/split_img/boot.img-board
	if [ $N8PORT == "1" ]; then
		sudo sed -i -- 's/ro.sf.lcd_density=420/ro.sf.lcd_density=480/g' $WORKDIR/ramdisk/ramdisk/default.prop
		sudo sed -i -- 's/ro.sf.init.lcd_density=560/ro.sf.init.lcd_density=640/g' $WORKDIR/ramdisk/ramdisk/default.prop
	fi
	cd $WORKDIR/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
else
	cd $WORKDIR/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
fi
}

# Build boot.img Function
FUNC_BUILD_BOOTIMG()
{
	(
	FUNC_CLEAN
	FUNC_COPY
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_DTB
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $LOGFILE
}

# Build Zip Function
FUNC_BUILD_ZIP()
{
echo ""
echo "Preparing Zip File  ..."
echo ""
echo "- Building anykernel2.zip file ..."
cd $ZIPDIR/tgpkernel/anykernel2
rm -f $ZIPDIR/tgpkernel/anykernel2/.git.zip
[ -d $ZIPDIR/tgpkernel/anykernel2/.git ] && rm -rf $ZIPDIR/tgpkernel/anykernel2/.git
zip -9gq anykernel2.zip -r * -x "*~"
echo "  Deleting unwanted files ..."
rm -rf META-INF tgpkernel patch tools anykernel.sh README.md
echo "- Building system.tar.xz file ..."
cd $ZIPDIR/tgpkernel
tar -cf - system/ | xz -9 -c - > system.tar.xz
mv -f system.tar.xz $ZIPDIR/tgpkernel/files/system.tar.xz
cd ..
rm -rf $ZIPDIR/tgpkernel/system
cd $ZIPDIR/tgpkernel/kernels
echo "- Generating MD5 checks for boot.img files ..."
echo "  boot2.md5"
MD5=$(md5sum "boot2.img" | cut -d ' ' -f 1)
echo $MD5 > boot2.md5
echo "  boot3.md5"
MD5=$(md5sum "boot3.img" | cut -d ' ' -f 1)
echo $MD5 > boot3.md5
echo "  boot4.md5"
MD5=$(md5sum "boot4.img" | cut -d ' ' -f 1)
echo $MD5 > boot4.md5
echo "  boot5.md5"
MD5=$(md5sum "boot5.img" | cut -d ' ' -f 1)
echo $MD5 > boot5.md5
echo "  boot6.md5"
MD5=$(md5sum "boot6.img" | cut -d ' ' -f 1)
echo $MD5 > boot6.md5
echo "- Creating boot.img.p files ..."
echo "  boot2.img.p"
bsdiff boot.img boot2.img boot2.img.p
echo "  boot3.img.p"
bsdiff boot.img boot3.img boot3.img.p
echo "  boot4.img.p"
bsdiff boot.img boot4.img boot4.img.p
echo "  boot5.img.p"
bsdiff boot.img boot5.img boot5.img.p
echo "  boot6.img.p"
bsdiff boot.img boot6.img boot6.img.p
echo "- Building kernels.tar.xz file ..."
rm -f boot2.img
rm -f boot3.img
rm -f boot4.img
rm -f boot5.img
rm -f boot6.img
cd $ZIPDIR/tgpkernel
tar -cf - kernels/ | xz -9 -c - > kernels.tar.xz
mv -f kernels.tar.xz $ZIPDIR/tgpkernel/files/kernels.tar.xz
cd ..
rm -rf $ZIPDIR/tgpkernel/kernels
echo ""
echo "Building final zip ..."
cd $ZIPDIR
zip -9gq $ZIP_NAME -r META-INF/ -x "*~"
zip -9gq $ZIP_NAME -r tgpkernel/ -x "*~" 
if [ -n `which java` ]; then
	echo "- Java detected, signing zip ..."
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar $RDIR/.build/signapk/signapk.jar -w $RDIR/.build/signapk/testkey.x509.pem $RDIR/.build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $OUTPUT/$ZIP_NAME
cd $RDIR
}

# Start of build script
echo ""
echo "-----------------------------------"
echo "- TGPKernel Build Script by djb77 -"
echo "-----------------------------------"
echo ""
sudo echo ""
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ -d "$RDIR/.build" ] && rm -rf $RDIR/.build
[ -d "$OUTPUT" ] && rm -rf $OUTPUT
mkdir $ZIPDIR
mkdir $OUTPUT
cp -rf $RDIR/build .build
cp -rf $RDIR/.build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels
START_TIME=`date +%s`
# Build S7 r12p0 .img files
echo ""
echo "Building S8 .img files"
echo "----------------------"
echo ""
S8=1
git checkout tw70 -f
MODEL=dreamlte
export ANDROIDVERSION=N
export KERNELTITLE=$KERNELNAME.$ANDROIDVERSION.$VERSION_NUMBER
KERNEL_DEFCONFIG=$KERNELCONFIG-dreamlte_eur_open_defconfig
LOGFILE=$OUTPUT/build-s8-tw70.log
FUNC_BUILD_BOOTIMG
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot.img
rm -rf $RDIR/net
git checkout tw70 -f
MODEL=dream2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-dream2lte_eur_open_defconfig
LOGFILE=$OUTPUT/build-s8+-tw70.log
FUNC_BUILD_BOOTIMG
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot2.img

# Build N8 Port .img files
echo ""
echo "Building N8 Port .img files"
echo "---------------------------"
echo ""
S8=0
N8PORT=1
rm -rf $RDIR/net
git checkout tw711 -f
export ANDROIDVERSION=N8Port
export KERNELTITLE=$KERNELNAME.$ANDROIDVERSION.$VERSION_NUMBER
MODEL=dreamlte
KERNEL_DEFCONFIG=$KERNELCONFIG-dreamlte_eur_open_defconfig
LOGFILE=$OUTPUT/build-s8-tw711.log
FUNC_BUILD_BOOTIMG
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot3.img
rm -rf $RDIR/net
git checkout tw711 -f
MODEL=dream2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-dream2lte_eur_open_defconfig
LOGFILE=$OUTPUT/build-s8+-tw711.log
FUNC_BUILD_BOOTIMG
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/boot4.img

# Final archiving
echo ""
echo "Final archiving"
echo "---------------"
echo ""
rm -rf $RDIR/net
git checkout build -f
if [ $KEEP = "yes" ]; then
	echo ""
	echo "Copying .img files to output folder ..."
	cp -f $ZIPDIR/tgpkernel/kernels/boot.img $OUTPUT/boot.img
	cp -f $ZIPDIR/tgpkernel/kernels/boot2.img $OUTPUT/boot2.img
	cp -f $ZIPDIR/tgpkernel/kernels/boot3.img $OUTPUT/boot3.img
	cp -f $ZIPDIR/tgpkernel/kernels/boot4.img $OUTPUT/boot4.img
  	cp -f $ZIPDIR/tgpkernel/kernels/boot5.img $OUTPUT/boot5.img
  	cp -f $ZIPDIR/tgpkernel/kernels/boot6.img $OUTPUT/boot6.img
fi
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G95xx.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
FUNC_CLEAN
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ -d "$RDIR/.build" ] && rm -rf $RDIR/.build
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo "You will find your logs and files in the output folder"
echo ""
exit

