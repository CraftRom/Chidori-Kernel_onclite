#!/bin/bash
#
# Compile script for Cartel kernel
# Copyright (C) 2021 Craft Rom (melles1991).

SECONDS=0 # builtin bash timer

#Set Color
blue='\033[0;34m'
grn='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
txtbld=$(tput bold)
txtrst=$(tput sgr0)  

echo -e " "
echo -e " "
echo -e "$blue░▐█▀█░▐█░▐█░▐██░▐█▀█▄▒▐█▀▀█▌▒▐█▀▀▄░▐██"
echo -e "░▐█──░▐████─░█▌░▐█▌▐█▒▐█▄▒█▌▒▐█▒▐█─░█▌"
echo -e "░▐█▄█░▐█░▐█░▐██░▐█▄█▀▒▐██▄█▌▒▐█▀▄▄░▐██$nocol"
echo -e " "
  
# Main environtment
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$KERNEL_DIR/AnyKernel3
CONFIG=onclite-perf_defconfig

# Export
export ARCH=arm64
export CROSS_COMPILE
export CROSS_COMPILE_ARM32
export KBUILD_BUILD_USER=melles1991
export KBUILD_BUILD_HOST=CraftRom-build


echo -e "${txtbld}Config:${txtrst} $CONFIG"
echo -e "${txtbld}ARCH:${txtrst} $ARCH"
echo -e "${txtbld}Username:${txtrst} $KBUILD_BUILD_USER"
echo -e " "

if [[ $1 == "-c" || $1 == "--clean" ]]; then
if [  -d "./out/" ]; then
echo -e " "
        rm -rf ./out/
fi
echo -e "$grn \nFull cleaning was successful succesfully!\n $nocol"
sleep 2
fi

if [[ $1 == "-r" || $1 == "--regen" ]]; then
make $CONFIG
cp .config arch/arm64/configs/$CONFIG
git commit -am "defconfig: onclite: Regenerate" --signoff
echo -e "$grn \nRegened defconfig succesfully!\n $nocol"
make mrproper
echo -e "$grn \nCleaning was successful succesfully!\n $nocol"
sleep 4
exit 1
fi

# Main Staff
clang_bin="$HOME/toolchains/proton-clang/bin"
gcc_prefix64="aarch64-linux-gnu-"
gcc_prefix32="arm-linux-gnueabi-"
CROSS_COMPILE="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

_ksetup_old_path="$PATH"
export PATH="$clang_bin:$PATH"

# Build start
echo -e "$blue    \nMake DefConfig\n $nocol"
make	O=out $CONFIG
echo -e "$blue    \nStarting kernel compilation...\n $nocol"
make	-j`nproc --all` O=out ARCH=arm64 CC="clang" LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img

if ! [ -a $KERN_IMG ]; then
    echo -e "$red \nKernel Compilation failed! Fix the errors!\n $nocol"
fi

cd $ZIP_DIR
make clean &>/dev/null
cd ..

# For MIUI Build
# Credit Adek Maulana <adek@techdro.id>
OUTDIR="$KERNEL_DIR/out/"
VENDOR_MODULEDIR="$KERNEL_DIR/AnyKernel3/modules/vendor/lib/modules"

STRIP="$HOME/toolchains/proton-clang/aarch64-linux-gnu/bin/strip$(echo "$(find "$HOME/toolchains/proton-clang/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
            sed -e 's/gcc/strip/')"
for MODULES in $(find "${OUTDIR}" -name '*.ko'); do
    "${STRIP}" --strip-unneeded --strip-debug "${MODULES}"
    "${OUTDIR}"/scripts/sign-file sha512 \
            "${OUTDIR}/certs/signing_key.pem" \
            "${OUTDIR}/certs/signing_key.x509" \
            "${MODULES}"
    find "${OUTDIR}" -name '*.ko' -exec cp {} "${VENDOR_MODULEDIR}" \;
done
cd libufdt/src && python2 mkdtboimg.py create $OUTDIR/arch/arm64/boot/dtbo.img $OUTDIR/arch/arm64/boot/dts/qcom/*.dtbo
echo -e "$grn    \n(i)          Done moving modules\n $nocol"

cd $ZIP_DIR
cp $KERN_IMG zImage
cp $OUTDIR/arch/arm64/boot/dtbo.img $ZIP_DIR
make normal &>/dev/null
echo -e "$grn \n(i)          Completed build$nocol $red$((SECONDS / 60))$nocol $grn minute(s) and $nocol $red $((SECONDS % 60))$nocol second(s) !$nocol"
echo -e "$blue    \nFlashable zip generated under $yellow$ZIP_DIR.\n $nocol"
cd ..
# Build end
