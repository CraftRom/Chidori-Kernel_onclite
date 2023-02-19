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
DEFCONFIG="onclite-perf_defconfig"

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
		make clean
		rm -rf ./out/
	fi
	rm -f *zip
	echo -e "${GREEN} \nFull cleaning was successful succesfully!\n ${NOCOLOR}"
	sleep 5
	exit 1
}

regen() {
    # Export defconfig
    echo -e "${BLUE}--   Make DefConfig\n ${NOCOLOR}"
    mkdir -p out
    make -j$(nproc) O=out ARCH=arm64 "$DEFCONFIG"

    cp out/.config "arch/arm64/configs/$DEFCONFIG"
	sed -i '52s/.*/CONFIG_LOCALVERSION="-Chidori-Kernel"/' "arch/arm64/configs/$DEFCONFIG"
	git commit -am 'defconfig: onclite: Regenerate' --signoff
	echo -e "${GREEN}Regened defconfig successfully!\n ${NOCOLOR}"
	make clean
	echo -e "${GREEN}Cleaning was successful successfully!\n ${NOCOLOR}"
	sleep 10
	exit 0
}

desc() {
    echo -en "\nYou did not specify the build's description! Do you want to set it?\n(${GREEN}Y${NOCOLOR}/${RED}N${NOCOLOR}): "
    read -r ans
    case "$ans" in
        n)
            echo -e "\n${YELLOW}OK, the build will have no description...${NOCOLOR}\n"
            ;;
        y)
            echo -en "Type in the build's description: "
            read -r DESC
            echo -e "${GREEN}OK, saved!${NOCOLOR}"
			echo -e "${BOLD}Description:${NORMAL} ${GREEN}$DESC ${NOCOLOR}\n"
            sleep 1.5
            ;;
		*)
            echo -e "\nTry again!\n"
			desc
            ;;	
    esac
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--clean)
	  clean
      ;;
    -r|--regen)
      regen
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
kernel="out/arch/arm64/boot/Image.gz-dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

# Set exclude patterns for tar command
EXCLUDE="Makefile *.git* *.jar* *placeholder* *.md*"


# Set builder name based on hostname
if [[ -n "$HOSTNAME" ]]; then
    case $HOSTNAME in
        melles*)
            BUILDER='@mrshterben'
            ;;
        *)
            BUILDER='unknown'
            ;;
    esac
fi

# Print build information
echo -e "${BOLD}[Type]      :${NORMAL} $TYPE"
echo -e "${BOLD}[Config]    :${NORMAL} $DEFCONFIG"
echo -e "${BOLD}[ARCH]      :${NORMAL} arm64"
echo -e "${BOLD}[Linux]     :${NORMAL} $KERN_VER"
echo -e "${BOLD}[Username]  :${NORMAL} $KBUILD_BUILD_USER"
echo -e "${BOLD}[Builder]   :${NORMAL} $BUILDER"
echo -e "${BOLD}[BuildDate] :${NORMAL} $BUILD_DATE"
echo -e "${BOLD}[Filename]  :${NORMAL} $ZIP_NAME"
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
        https://api.telegram.org/$BOT/sendMessage \
        -d chat_id="-1001695676652" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

push_document() {
    curl -s -X POST \
        https://api.telegram.org/$BOT/sendDocument \
        -F chat_id="-1001695676652" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

# Check for description
if ! $description_was_specified; then
desc
fi

    # Export defconfig
    echo -e "${BLUE}--   Make DefConfig\n ${NOCOLOR}"
    mkdir -p out
    make -j$(nproc) O=out ARCH=arm64 "$DEFCONFIG"
	
    # Start kernel compilation
    echo -e "${BLUE}\n--   Starting kernel compilation...\n${NOCOLOR}"
    make -j$(nproc) O=out ARCH=arm64 CC="ccache clang" LD="ccache ld.lld" AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

    # Check if kernel and dtbo files exist
    if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
        echo -e "${BLUE}\nKernel compiled successfully! Zipping up...\n${NOCOLOR}"

    # Clone AnyKernel3 if not already present
    if ! [ -d "AnyKernel3" ]; then
        echo -e "${GREEN}\nAnyKernel3 not found! Cloning...\n${NOCOLOR}"
        if ! git clone https://github.com/CraftRom/AnyKernel3 -b onclite AnyKernel3; then
            echo -e "${GREEN}\nCloning failed! Aborting...\n${NOCOLOR}"
            sleep 10
			exit 1
        fi
	fi	
	# Move kernel and dtbo files to AnyKernel3 directory
	# Remove old ZIP files
    mv out/arch/arm64/boot/Image.gz-dtb out/arch/arm64/boot/dtbo.img AnyKernel3/ && rm -f *zip
	# Create new ZIP file
    cd AnyKernel3
    ZIP_CMD="zip -r9 ../$ZIP_NAME.zip . -q -x $EXCLUDE README.md *placeholder"
	echo -e "${BLUE}\n--   Creating ZIP: $ZIP_NAME.zip.zip\n${NOCOLOR}"
    eval $ZIP_CMD
	# Sign the ZIP file with AOSP keys
    echo -e "${BLUE}\n--   Signing zip with aosp keys...\n${NOCOLOR}"
    JAVA_CMD="java -jar *.jar* ../$ZIP_NAME.zip ../$ZIP_NAME-signed.zip"
    eval $JAVA_CMD
	# Delete temporary files
	rm -rf out/arch/arm64/boot
    cd ..
	
	if [[ -f "$ZIP_NAME-signed.zip" ]]; then
    # Push kernel to Telegram
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
        <b>md5 checksum:</b> <code>$(md5sum "$ZIP_NAME-signed.zip" | cut -d' ' -f1)</code>

        #onclite #onc #kernel"

        echo -e "${GREEN}\n(i) Send to telegram successfully!\n${NOCOLOR}"
    fi

    # Remove the "-experimental" from the kernel config file
    sed -i "52s/-experimental//" arch/arm64/configs/$DEFCONFIG

    # Output the completion message
    echo -e "${GREEN}\n(i) Completed build in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!\n${NOCOLOR}"
    echo -e "${BLUE}\nFlashable zip generated: ${YELLOW}$ZIP_NAME\n${NOCOLOR}"
else
    # Output the error message and push notification
    echo -e "${RED}\nKernel Compilation failed! Fix the errors!\n${NOCOLOR}"
    push_message "$BUILDER! <b>Failed building kernel for <code>$DEVICE</code> Please fix it...!</b>"
fi
fi
