#!/bin/bash
#
# Compile script for Chidori Kernel
# Copyright (C) 2020-2021 Adithya R & @johnmart19.
# Copyright (C) 2021-2023 Chidori Kernel developers
#
# Optimize whith ChatGPT


SECONDS=0 # builtin bash timer

set -euo pipefail  # set strict mode


# Set colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NOCOLOR='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Parse command-line options
clean=false
regen=false
do_not_send_to_tg=false
description_was_specified=false

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Compile script for Chidori Kernel"
    echo ""
    echo "OPTIONS:"
    echo "  -c, --clean        Remove files in out folder for clean build."
    echo "  -r, --regen        Regenerate files before building."
    echo "  -l, --local-build  Do not send build status to Telegram."
    echo "  -d, --desc DESC    Add a description for build."
    echo "  -n, --nightly      Build a nightly kernel."
    echo "  -s, --stable       Build a stable kernel."
    echo "  -e, --exp          Build an experimental kernel."
    echo "  -h, --help         Show this help message and exit."
	sleep 360
    brerake
}

# Clean build directory if requested
clean() {
	if [  -d "./out/" ]; then
		echo -e " "
		rm -rf ./out/
	fi
	echo -e "${GREEN} \nFull cleaning was successful succesfully!\n ${NOCOLOR}"
	sleep 5
	exit 1
}

TYPE=nightly
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--clean)
	  clean
      ;;
    -r|--regen*)
      regen=true
      ;;
    -l|--local*)
      do_not_send_to_tg=true
      ;;
    -d|--desc*)
      if [[ $# -eq 0 || ${1:0:1} == "-" ]]; then
        usage
      fi
      description_was_specified=true
      DESC="$1"
      shift
      ;;
    -n|--night*)
      TYPE=nightly
      ;;
    -s|--stab*)
      TYPE=stable
      ;;
    -e|--exp*)
      TYPE=experimental
      ;;
	-h|--help)
      usage
      ;;
    *)
      echo -e "${RED}ERROR: Unknown option $1 ${NOCOLOR}"
	  sleep 10
	  exit 0
      ;;
  esac
  shift
done

# Print logo
echo -e " "
echo -e " "
echo -e "${BLUE}░▐█▀█░▐█░▐█░▐██░▐█▀█▄▒▐█▀▀█▌▒▐█▀▀▄░▐██"
echo -e "░▐█──░▐████─░█▌░▐█▌▐█▒▐█▄▒█▌▒▐█▒▐█─░█▌"
echo -e "░▐█▄█░▐█░▐█░▐██░▐█▄█▀▒▐██▄█▌▒▐█▀▄▄░▐██${NOCOLOR}"
echo -e " "

#Set default value for TYPE if it not set
case $TYPE in nightly|stable);; *)TYPE=experimental;; esac

# debug:
#echo "`date`: $clean $regen $help $do_not_send_to_tg $TYPE $DESC" >>build_sh.log

# Set kernel version and other variables
KERN_VER=$(make kernelversion | grep -v make | head -n 1)
BUILD_DATE=$(date '+%Y-%m-%d %H:%M')
DEVICE="Redmi 7/Y3"
KERNEL_NAME="Chidori-Kernel-$TYPE"
ZIP_NAME="Chidori-Kernel-onclite-$(date '+%Y%m%d%H%M')-$TYPE"
TC_DIR="$HOME/toolchains/proton-clang"
DEFCONFIG="onclite-perf_defconfig"

# Set kernel name in config file
sed -i "52s/.*/CONFIG_LOCALVERSION=\"-$KERNEL_NAME\"/g" arch/arm64/configs/$DEFCONFIG

# Set environment variables
export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="melles1991"
export KBUILD_BUILD_HOST="CraftRom-build"

# Set exclude patterns for tar command
EXCLUDE="Makefile *.git* *.jar* *placeholder* *.md*"


# Set builder name based on hostname
if [[ -n "$HOSTNAME" ]]; then
    case $HOSTNAME in
        IgorK-*)
            BUILDER='@DfP_DEV'
            ;;
        *)
            BUILDER='@mrshterben'
            ;;
    esac
fi

# Print build information
echo -e "${BOLD}Type:${NORMAL} $TYPE"
echo -e "${BOLD}Config:${NORMAL} $DEFCONFIG"
echo -e "${BOLD}ARCH:${NORMAL} arm64"
echo -e "${BOLD}Linux:${NORMAL} $KERN_VER"
echo -e "${BOLD}Username:${NORMAL} $KBUILD_BUILD_USER"
echo -e "${BOLD}Builder:${NORMAL} $BUILDER"
echo -e "${BOLD}BuildDate:${NORMAL} $BUILD_DATE"
echo -e "${BOLD}Filename:${NORMAL} $ZIP_NAME"
echo -e ""

# Clone Proton Clang if not already present
if [[ ! -d "$TC_DIR" ]]; then
	echo -e "${GREEN} \nProton clang not found! Cloning to $TC_DIR...\n ${NOCOLOR}"
	if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $TC_DIR; then
		echo -e "${RED} \nCloning failed! Aborting...\n ${NOCOLOR}"
		exit 1
	fi
fi


# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot5579959772:AAHJ1cvfipl05kxYhNQBvLy7b60vGmeQSRE/sendMessage \
        -d chat_id="-1001695676652" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

push_document() {
    curl -s -X POST \
        https://api.telegram.org/bot5579959772:AAHJ1cvfipl05kxYhNQBvLy7b60vGmeQSRE/sendDocument \
        -F chat_id="-1001695676652" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

# Export defconfig
echo -e "${BLUE}    \nMake DefConfig\n ${NOCOLOR}"
mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

if $regen; then
	cp out/.config arch/arm64/configs/$DEFCONFIG
	sed -i "52s/.*/CONFIG_LOCALVERSION=\"-Chidori-Kernel\"/g" arch/arm64/configs/$DEFCONFIG
	git commit -am "defconfig: onclite: Regenerate" --signoff
	echo -e "${GREEN]} \nRegened defconfig succesfully!\n ${NOCOLOR}"
	make mrproper
	echo -e "${GREEN} \nCleaning was successful succesfully!\n ${NOCOLOR}"
	sleep 4
	exit 0
fi

# Description check
if ! $description_was_specified; then
	echo -en "\n\tYou did not specify the build's description! Do you want to set it?\n\t(Y/n): "
	read ans
	case $ans in n)echo -e "\tOK, the build will have no description...\n";;
	*)
		echo -en "\n\t\tType in the build's description: "
		read DESC
		echo -e "\n\tOK, saved!\n"
		sleep 1.5
		;;
	esac
fi

# Build start
echo -e "${BLUE}    \nStarting kernel compilation...\n ${NOCOLOR}"
make -j$(nproc --all) O=out ARCH=arm64 CC="ccache clang" LD="ccache ld.lld" AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img


kernel="out/arch/arm64/boot/Image.gz-dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtbo" ]; then
	echo -e "${BLUE}    \nKernel compiled succesfully! Zipping up...\n ${NOCOLOR}"
	if ! [ -d "AnyKernel3" ]; then
		echo -e "${GREEN} \nAnyKernel3 not found! Cloning...\n ${NOCOLOR}"
		if ! git clone https://github.com/CraftRom/AnyKernel3 -b onclite AnyKernel3; then
			echo -e "${GREEN} \nCloning failed! Aborting...\n ${NOCOLOR}"
		fi
	fi

	cp $kernel $dtbo AnyKernel3
	rm -f *zip
	cd AnyKernel3
	echo -e "${BLUE}    \nCreating ZIP: $ZIP_NAME.zip.zip\n ${NOCOLOR}"
	zip -r9 "../$ZIP_NAME.zip" . -q -x $EXCLUDE README.md *placeholder
	echo -e "${BLUE}    \nSigning zip with aosp keys...\n ${NOCOLOR}"
	java -jar *.jar* "../$ZIP_NAME.zip" "../$ZIP_NAME-signed.zip"
	cd ..
	echo -e "${GREEN} \n(i)          Completed build${NOCOLOR} ${RED}$((SECONDS / 60))${NOCOLOR} ${GREEN} minute(s) and${NOCOLOR} ${RED}$((SECONDS % 60))${NOCOLOR} ${GREEN} second(s) !${NOCOLOR}"
	echo -e "${BLUE}    \n             Flashable zip generated ${YELLOW}$ZIP_NAME.\n ${NOCOLOR}"
	rm -rf out/arch/arm64/boot



	# Push kernel to telegram
	if ! $do_not_send_to_tg; then
		push_document "$ZIP_NAME-signed.zip" "
		<b>CHIDORI KERNEL | $DEVICE</b>

		New update available!
		
		<i>${DESC:-No description given...}</i>
		
		<b>Maintainer:</b> <code>$KBUILD_BUILD_USER</code>
		<b>Builder:</b> $BUILDER
		<b>Linux:</b> <code>$KERN_VER</code>
		<b>Type:</b> <code>$TYPE</code>
		<b>BuildDate:</b> <code>$BUILD_DATE</code>
		<b>Filename:</b> <code>$ZIP_NAME</code>
		<b>md5 checksum :</b> <code>$(md5sum "$ZIP_NAME-signed.zip" | cut -d' ' -f1)</code>

		#onclite #onc #kernel"

		echo -e "${GREEN} \n\n(i)          Send to telegram succesfully!\n ${NOCOLOR}"
	fi

	# TEMP
	sed -i "52s/-experimental//" arch/arm64/configs/$DEFCONFIG
else
	echo -e "${RED} \nKernel Compilation failed! Fix the errors!\n ${NOCOLOR}"
	# Push message if build error
	push_message "$BUILDER! <b>Failed building kernel for <code>$DEVICE</code> Please fix it...!</b>"

fi