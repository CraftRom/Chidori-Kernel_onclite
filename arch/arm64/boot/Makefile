#
# arch/arm64/boot/Makefile
#
# This file is included by the global makefile so that you can add your own
# architecture-specific flags and dependencies.
#
# This file is subject to the terms and conditions of the GNU General Public
# License.  See the file "COPYING" in the main directory of this archive
# for more details.
#
# Copyright (C) 2012, ARM Ltd.
# Author: Will Deacon <will.deacon@arm.com>
#
# Based on the ia64 boot/Makefile.
#
# Copyright (C) 2023, ChatGPT.
# Author: Dmytro Galytskyi <melles.android@gmail.com>
#

include $(srctree)/arch/arm64/boot/dts/Makefile

OBJCOPYFLAGS_Image :=-O binary -R .note -R .note.gnu.build-id -R .comment -S

targets := Image Image.bz2 Image.gz Image.lz4 Image.lzma Image.lzo dtbo.img

DTB_NAMES := $(subst $\",,$(CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE_NAMES))
ifeq ($(strip $(DTB_NAMES)),)
DTB_OBJS := $(shell find $(obj)/dts/ -name "*.dtb")
else
DTB_OBJS := $(addprefix $(obj)/dts/,$(addsuffix .dtb,$(DTB_NAMES)))
endif

DTBO_OBJS := $(shell find $(obj)/dts/ -name "*.dtbo")

ifdef RTIC_MPGEN
DTB_OBJS += rtic_mp.dtb
endif

rtic_mp.dtb: vmlinux FORCE
	$(RTIC_MPGEN) --objcopy="$(OBJCOPY)" --objdump="$(OBJDUMP)" \
	--binpath="" --vmlinux="vmlinux" --config=$(KCONFIG_CONFIG) \
	--cc="$(CC)" --dts=rtic_mp.dts && \
	$(DTC) -O dtb -o $@ -b 0 $(DTC_FLAGS) $<

$(obj)/Image: vmlinux FORCE
	$(call if_changed,objcopy)

$(obj)/Image.bz2: $(obj)/Image FORCE
	$(call if_changed,bzip2)

$(obj)/Image-dtb-hdr: $(obj)/Image FORCE
	echo -n 'UNCOMPRESSED_IMG' > $@ && \
	$(call size_append, $(filter-out FORCE,$^)) >> $@

$(obj)/Image-dtb: $(obj)/Image-dtb-hdr $(obj)/Image $(DTB_OBJS) FORCE
	$(call if_changed,cat)

$(obj)/Image.gz: $(obj)/Image FORCE
	$(call if_changed,gzip)

$(obj)/Image.lz4: $(obj)/Image FORCE
	$(call if_changed,lz4)

$(obj)/Image.lzma: $(obj)/Image FORCE
	$(call if_changed,lzma)

$(obj)/Image.lzo: $(obj)/Image FORCE
	$(call if_changed,lzo)

$(obj)/Image.gz-dtb: $(obj)/Image.gz $(DTB_OBJS) FORCE
	$(call if_changed,cat)

$(obj)/dtbo.img: $(DTBO_OBJS) FORCE
	$(call if_changed,mkdtimg)

install zinstall:
	$(CONFIG_SHELL) $(srctree)/$(src)/install.sh $(KERNELRELEASE) \
	$(obj)/$(subst install,Image,$@) System.map "$(INSTALL_PATH)"
