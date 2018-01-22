#!/bin/bash
# Build Script By Tkkg1994 and djb77
# Modified by TheFlash & Illusion / XDA Developers

# ---------
# VARIABLES
# ---------
VERSION_NUMBER=v1
ARCH=arm64
#BUILD_CROSS_COMPILE=~/toolchains/arm64/linaro7.2/bin/aarch64-linux-gnu-
BUILD_CROSS_COMPILE=~/toolchains/arm64/google/bin/aarch64-linux-android-
#BUILD_CROSS_COMPILE=~/toolchains/arm64/sabermod/bin/aarch64-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
PAGE_SIZE=2048
KERNELNAME=SkyLight_Kernel
KERNEL_DEFCONFIG=SkyLight_defconfig
ZIPLOC=zip

# Colours
bldred=${txtbld}$(tput setaf 1) # red
bldblu=${txtbld}$(tput setaf 4) # blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtrst=$(tput sgr0) # Reset

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE clean
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE mrproper
rm -f $RDIR/build/build.log
rm -f $RDIR/build/build-*.log
rm -f $RDIR/arch/$ARCH/boot/boot.img-zImage
rm -f $RDIR/build/boot.img
rm -f $RDIR/build/*.zip
rm -f $RDIR/build/AIK/N920*/image-new.img
rm -f $RDIR/build/AIK/N920*/ramdisk-new.cpio.gz
rm -f $RDIR/build/AIK/N920*/split_img/boot.img-zImage
rm -f $RDIR/build/AIK/N920*/image-new.img
rm -f $RDIR/build/$ZIPLOC/N920*/*.zip
rm -f $RDIR/build/$ZIPLOC/N920*/*.img
}

FUNC_BUILD_ZIMAGE()
{
echo ""
echo "build common config="$KERNEL_DEFCONFIG ""
echo "build variant config="$VARIANT_DEFCONFIG ""
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
     CROSS_COMPILE=$BUILD_CROSS_COMPILE \
     $KERNEL_DEFCONFIG \
     VARIANT_DEFCONFIG=$VARIANT_DEFCONFIG || exit -1
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
     CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
echo ""
}

FUNC_BUILD_RAMDISK()
{
# check if kernel build ok
if [ ! -e $RDIR/arch/$ARCH/boot/Image ]; then
	echo -e "\n${bldred}Kernel Not built! Check Build.log ${txtrst}\n"
	grep -B 3 -C 6 -r error: $RDIR/build/build.log
	grep -B 3 -C 6 -r warn $RDIR/build/build.log
	read -n 1 -s -p "Press any key to continue"
	exit
fi

if [ ! -f "$RDIR/build/AIK/N920*/ramdisk/config" ]; then
	mkdir $RDIR/build/AIK/N920*/ramdisk/config
	chmod 500 $RDIR/build/AIK/N920*/ramdisk/config
fi

mv $RDIR/arch/$ARCH/boot/Image $RDIR/arch/$ARCH/boot/boot.img-zImage
case $MODEL in
noblelteskt)
	rm -f $RDIR/build/AIK/N920S/split_img/boot.img-zImage
	mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/build/AIK/N920S/split_img/boot.img-zImage
	cd $RDIR/build/AIK/N920S
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
nobleltektt)
	rm -f $RDIR/build/AIK/N920K/split_img/boot.img-zImage
	mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/build/AIK/N920K/split_img/boot.img-zImage
	cd $RDIR/build/AIK/N920K
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
nobleltelgt)
	rm -f $RDIR/build/AIK/N920L/split_img/boot.img-zImage
	mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/build/AIK/N920L/split_img/boot.img-zImage
	cd $RDIR/build/AIK/N920L
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
}

FUNC_BUILD_BOOTIMG()
{
	(
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $RDIR/build/build.log
}

FUNC_BUILD_ZIP()
{
echo ""
echo "Building Zip File"
cd $ZIP_FILE_DIR
zip -gq $ZIP_NAME -r META-INF/ -x "*~"
[ -f "$RDIR/build/$ZIPLOC/N920S/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
[ -f "$RDIR/build/$ZIPLOC/N920K/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
[ -f "$RDIR/build/$ZIPLOC/N920L/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $RDIR/build/$ZIP_NAME
cd $RDIR
}

OPTION_1()
{
rm -f $RDIR/build/build.log
MODEL=noblelteskt
VARIANT_DEFCONFIG=N920S_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920S/image-new.img $RDIR/build/$ZIPLOC/N920S/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920S.log
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920S
ZIP_NAME=$KERNELNAME.N920S.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Build Successful"
echo ""
echo "Compiled in $ELAPSED_TIME seconds"
echo ""
}

OPTION_2()
{
rm -f $RDIR/build/build.log
MODEL=nobleltekkt
VARIANT_DEFCONFIG=N920K_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920K/image-new.img $RDIR/build/$ZIPLOC/N920K/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920K.log
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920K
ZIP_NAME=$KERNELNAME.N920K.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Build Successful"
echo ""
echo "Compiled in $ELAPSED_TIME seconds"
echo ""
}

OPTION_3()
{
rm -f $RDIR/build/build.log
MODEL=nobleltelgt
VARIANT_DEFCONFIG=N920L_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920L/image-new.img $RDIR/build/$ZIPLOC/N920L/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920L.log
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920L
ZIP_NAME=$KERNELNAME.N920L.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Build Successful"
echo ""
echo "Compiled in $ELAPSED_TIME seconds"
echo ""
}

OPTION_4()
{
rm -f $RDIR/build/build.log
KERNEL_DEFCONFIG=SkyLight_defconfig
MODEL=noblelteskt
VARIANT_DEFCONFIG=N920S_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920S/image-new.img $RDIR/build/$ZIPLOC/N920S/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920S.log
MODEL=nobleltekkt
VARIANT_DEFCONFIG=N920K_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920K/image-new.img $RDIR/build/$ZIPLOC/N920K/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920K.log
MODEL=nobleltelgt
VARIANT_DEFCONFIG=N920L_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/AIK/N920L/image-new.img $RDIR/build/$ZIPLOC/N920L/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-N920L.log
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920S
ZIP_NAME=$KERNELNAME.N920S.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920K
ZIP_NAME=$KERNELNAME.N920K.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/N920L
ZIP_NAME=$KERNELNAME.N920L.$VERSION_NUMBER.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip files in the build folder"
echo ""
exit
}

OPTION_0()
{
echo "${bldred} Cleaning Workspace ${txtrst}"
FUNC_CLEAN
}

# Program Start
rm -rf ./build/build.log
clear
echo "${txtrst}"
echo " ${bldblu} 0) Clean Workspace ${txtrst}"
echo ""
echo " ${bldblu} 1) Build SkyLight Kernel for SM-N920S ${txtrst}"
echo ""
echo " ${bldblu} 2) Build SkyLight Kernel for SM-N920K ${txtrst}"
echo ""
echo " ${bldblu} 3) Build SkyLight Kernel for SM-N920L ${txtrst}"
echo ""
echo " ${bldblu} 4) Build SkyLight Kernel for three devices above ${txtrst}"
echo ""
read -p " ${bldcya}Please select an option: ${txtrst}" prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
	echo ""
	echo ""
	echo ""
	echo ""
	. build.sh
elif [ $prompt == "1" ]; then
	OPTION_1
	echo ""
	echo ""
	echo ""
	echo ""
	read -n 1 -s -p "Press any key to continue"
	echo ""
	echo ""
elif [ $prompt == "2" ]; then
	OPTION_2
	echo ""
	echo ""
	echo ""
	echo ""
	read -n 1 -s -p "Press any key to continue"
	echo ""
	echo ""
elif [ $prompt == "3" ]; then
	OPTION_3
	echo ""
	echo ""
	echo ""
	echo ""
	read -n 1 -s -p "Press any key to continue"
	echo ""
	echo ""
elif [ $prompt == "4" ]; then
	OPTION_4
	echo ""
	echo ""
	echo ""
	echo ""
	read -n 1 -s -p "Press any key to continue"
	echo ""
	echo ""
fi
