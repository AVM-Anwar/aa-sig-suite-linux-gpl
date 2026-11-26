#!/bin/bash
# Rebuild AA Signature Suite for Linux's snd-usb-audio module from source:
#   ./build.sh            -> out/snd-usb-audio.ko (for Arch Linux kernel 7.3.5-arch1-1)
# Needs: bash, curl, tar, xz, zstd, patch, make, gcc (and the kernel's build tools: bc, flex, bison, libelf).
# Downloads the kernel.org source of Linux 7.3.5 (only sound/usb is used) and Arch's linux-headers
# 7.3.5.arch1-1 (the configured build tree of the kernel AA Signature Suite for Linux runs), applies the patches in
# patches/ in name order, and builds the module out of tree.
set -eu
V=7.3.5; R=7.3.5.arch1-1; K=7.3.5-arch1-1; A=v7.3.5-arch1
D=$(cd "$(dirname "$0")" && pwd); W="$D/work"; O="$D/out"
mkdir -p "$W"; cd "$W"
[ -s headers.pkg.tar.zst ] || curl -sfL --retry 5 -o headers.pkg.tar.zst "https://archive.archlinux.org/packages/l/linux-headers/linux-headers-$R-x86_64.pkg.tar.zst"
[ -s linux-$V.tar.xz ] || curl -sfL --retry 5 -o linux-$V.tar.xz "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$V.tar.xz"
[ -s arch.patch.zst ] || curl -sfL --retry 5 -o arch.patch.zst "https://github.com/archlinux/linux/releases/download/$A/linux-$A.patch.zst"
n=$(zstdcat arch.patch.zst | grep -cE '^\+\+\+ b/sound/usb/' || true)
[ "$n" = 0 ] || { echo "Arch's patch $A changes sound/usb ($n file(s)): apply it too before building"; exit 1; }
rm -rf hdr src; mkdir hdr src
tar -C hdr -xf headers.pkg.tar.zst usr/lib/modules
tar -C src -xf linux-$V.tar.xz "linux-$V/sound/usb"
B="$W/hdr/usr/lib/modules/$K/build"; S="$W/src/linux-$V"
for p in "$D"/patches/*.patch; do
    patch -p1 -d "$S" --forward --quiet < "$p"
    echo "applied $(basename "$p")"
done
# the module names its patches (modinfo -F aa_patches; AA Signature Suite for Linux's System tab shows them)
names=$(for p in "$D"/patches/*.patch; do basename "$p" .patch; done | paste -sd' ')
printf '\n/* AA build: the patches applied */\nMODULE_INFO(aa_patches, "%s");\n' "$names" >> "$S/sound/usb/card.c"
make -s -C "$B" M="$S/sound/usb" modules -j"$(nproc)"
mkdir -p "$O"; cp "$S/sound/usb/snd-usb-audio.ko" "$O/"; strip --strip-debug "$O/snd-usb-audio.ko"
echo "built $O/snd-usb-audio.ko, vermagic $(modinfo -F vermagic "$O/snd-usb-audio.ko" 2>/dev/null || echo '?')"
