#!/bin/bash

export RK_KERNEL_GITHUB=https://github.com/armbian/linux-rockchip
export RK_KERNEL_BRANCH=rockchip-5.10

export ADS6401_PATCH_FILE=rk3568_linux_510_110_ads6401_for_mini_demo_box.patch

export LC_ALL=C
export LD_LIBRARY_PATH=

# Target arch
export RK_KERNEL_ARCH=arm64
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=rockchip_linux_defconfig
# Kernel dts
export RK_KERNEL_DTS=rk3568-evb1-ddr4-v10-linux
# boot image type
export RK_BOOT_IMG=boot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm64/boot/Image
# kernel image format type: fit(flattened image tree)
export RK_KERNEL_FIT_ITS=boot.its
# boot.its is from device\rockchip\rk356x\boot.its
# RK_KERNEL_DEFCONFIG_FRAGMENT is NULL

COMMON_DIR="$(dirname "$(realpath "$0")")"
TOP_DIR="$(realpath "$COMMON_DIR/../../..")"
cd "$TOP_DIR"
mkdir -p rockdev

CHIP_DIR="$(realpath $TOP_DIR/device/rockchip/rk3568)"

err_handler()
{
	ret=$?
	[ "$ret" -eq 0 ] && return

	echo "ERROR: Running ${FUNCNAME[1]} failed!"
	echo "ERROR: exit code $ret from line ${BASH_LINENO[0]}:"
	echo "    $BASH_COMMAND"
	exit $ret
}
trap 'err_handler' ERR
set -eE

check_config()
{
	unset missing
	for var in $@; do
		eval [ \$$var ] && continue

		missing="$missing $var"
	done

	[ -z "$missing" ] && return 0

	echo "Skipping ${FUNCNAME[1]} for missing configs: $missing."
	return 1
}

finish_build()
{
	echo "Running ${FUNCNAME[1]} succeeded."
	cd $TOP_DIR
}

git_clone_rockchip_kernel()
{
	echo "============Start download kernel for rk3568============"
	echo "KERNEL_GITHUB =$RK_KERNEL_GITHUB"
	cd $TOP_DIR
	git clone $RK_KERNEL_GITHUB kernel
	cd kernel
	git checkout $RK_KERNEL_BRANCH
}

apply_ads6401_patch()
{
	echo "============Start appyly patch for ads6401 sensor============"
	echo "PATCH_FILE =$ADS6401_PATCH_FILE"
	cd $TOP_DIR/kernel
    git apply ../$ADS6401_PATCH_FILE
}

setup_cross_compile()
{
	TOOLCHAIN_OS=none

	TOOLCHAIN_ARCH=${RK_KERNEL_ARCH/arm64/aarch64}
	TOOLCHAIN_DIR="$(realpath prebuilts/gcc/*/$TOOLCHAIN_ARCH/gcc-arm-*)"
	GCC="$(find "$TOOLCHAIN_DIR" -name "*$TOOLCHAIN_OS*-gcc")"
	if [ ! -x "$GCC" ]; then
		echo "No prebuilt GCC toolchain!"
		return 1
	fi

	export CROSS_COMPILE="${GCC%gcc}"
	echo "Using prebuilt GCC toolchain: $CROSS_COMPILE"

	NUM_CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
	JLEVEL=${RK_JOBS:-$(( $NUM_CPUS + 1 ))}
	KMAKE="make -C kernel/ ARCH=$RK_KERNEL_ARCH -j$JLEVEL"
}

build_kernel()
{
	check_config RK_KERNEL_DTS RK_KERNEL_DEFCONFIG || return 0

	echo "============Start building kernel============"
	echo "TARGET_KERNEL_ARCH   =$RK_KERNEL_ARCH"
	echo "TARGET_KERNEL_CONFIG =$RK_KERNEL_DEFCONFIG"
	echo "TARGET_KERNEL_DTS    =$RK_KERNEL_DTS"
	echo "TARGET_KERNEL_CONFIG_FRAGMENT =$RK_KERNEL_DEFCONFIG_FRAGMENT"
	echo "=========================================="

	setup_cross_compile

	$KMAKE $RK_KERNEL_DEFCONFIG $RK_KERNEL_DEFCONFIG_FRAGMENT
	$KMAKE $RK_KERNEL_DTS.img

	ITS="$CHIP_DIR/$RK_KERNEL_FIT_ITS"
	if [ -f "$ITS" ]; then
		$COMMON_DIR/mk-fitimage.sh kernel/$RK_BOOT_IMG \
			"$ITS" $RK_KERNEL_IMG
	fi

	ln -rsf kernel/$RK_BOOT_IMG rockdev/boot.img

	finish_build
}

build_modules()
{
	check_config RK_KERNEL_DEFCONFIG || return 0

	echo "============Start building kernel modules============"
	echo "TARGET_KERNEL_ARCH   =$RK_KERNEL_ARCH"
	echo "TARGET_KERNEL_CONFIG =$RK_KERNEL_DEFCONFIG"
	echo "TARGET_KERNEL_CONFIG_FRAGMENT =$RK_KERNEL_DEFCONFIG_FRAGMENT"
	echo "=================================================="

	setup_cross_compile

	$KMAKE $RK_KERNEL_DEFCONFIG $RK_KERNEL_DEFCONFIG_FRAGMENT
	$KMAKE modules

	finish_build
}

build_clean()
{
	echo "clean kernel"

	make -C kernel distclean

	finish_build
}

usage()
{
	echo "Usage: build.sh [OPTIONS]"
	echo "Available options:"
	echo "clone_kernel       -git clone kernel"
	echo "kernel             -build kernel"
	echo "clean              -clean kernel"
}

option=$1
echo "processing option: $option"
case $option in
	clean) build_clean ;;
	clone_kernel) git_clone_rockchip_kernel ;;
	apply_patch) apply_ads6401_patch ;;
	kernel) build_kernel ;;
	modules) build_modules ;;
	*) usage ;;
esac
