export ARCH=arm64
make onclite-perf_defconfig
cp .config arch/arm64/configs/onclite-perf_defconfig
git commit -am "defconfig: onclite: Regenerate" --signoff
