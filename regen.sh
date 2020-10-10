export ARCH=arm64
make onc-perf_defconfig
cp .config arch/arm64/configs/onc-perf_defconfig
git commit -am "defconfig: onc: Regenerate" --signoff
