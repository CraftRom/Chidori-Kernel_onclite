#!/bin/sh
#
# arch/arm64/boot/install.sh
#
# This file is subject to the terms and conditions of the GNU General Public
# License.  See the file "COPYING" in the main directory of this archive
# for more details.
#
# Copyright (C) 1995 by Linus Torvalds
# Copyright (C) 2023 by ChatGPT
#
# Adapted from code in arch/i386/boot/Makefile by H. Peter Anvin
# Adapted from code in arch/i386/boot/install.sh by Russell King
#
# "make install" script for the AArch64 Linux port
#
# Arguments:
#   $1 - kernel version
#   $2 - kernel image file
#   $3 - kernel map file
#   $4 - default install path (blank if root directory)
#

# Enable strict error checking
set -euo pipefail

# Verify that the kernel image and map files exist
verify () {
	if [ ! -f "$1" ]; then
		echo "" >&2
		echo " *** Missing file: $1" >&2
		echo ' *** You need to run "make" before "make install".' >&2
		echo "" >&2
		exit 1
	fi
}
verify "$2"
verify "$3"

# Check for a custom install script and run it if it exists
for path in ~/bin/${INSTALLKERNEL} /sbin/${INSTALLKERNEL}; do
	if [ -x "$path" ]; then
		exec "$path" "$@"
	fi
done

# Determine whether the kernel image is compressed or not
if [ "$(basename "$2")" = "Image.gz" ]; then
	echo "Installing compressed kernel"
	base=vmlinuz
else
	echo "Installing normal kernel"
	base=vmlinux
fi

# Install the kernel image file
if [ -f "$4/$base-$1" ]; then
	mv --backup=numbered "$4/$base-$1" "$4/$base-$1.old"
fi
cp "$2" --remove-destination "$4/$base-$1"

# Install the system map file
if [ -f "$4/System.map-$1" ]; then
	mv --backup=numbered "$4/System.map-$1" "$4/System.map-$1.old"
fi
cp "$3" --remove-destination "$4/System.map-$1"
