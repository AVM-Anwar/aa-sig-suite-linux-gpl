# AA Signature Suite for Linux – GPL source

AA Signature Suite for Linux is the music appliance system of AA Audio (aa-audio.com.my), built on Arch Linux.
This repository holds the source of the one GPL part we change: the Linux kernel's USB audio driver
(`sound/usb`, the `snd-usb-audio` module, GPL-2.0). Everything else in the system image is the unchanged
Arch Linux package of the version the image lists.

## What is changed

Kernel: Linux 7.3.5 as packaged by Arch Linux, `linux 7.3.5.arch1-1` (module vermagic `7.3.5-arch1-1`). Arch's kernel patch
`v7.3.5-arch1` does not change `sound/usb`, so the driver source is kernel.org's Linux 7.3.5 plus:

| Patch | What it does |
|---|---|
| [0001-urb-not-capped-to-feedback-interval](patches/0001-urb-not-capped-to-feedback-interval.patch) | Reduces USB interrupts: audio URBs are no longer cut to the feedback interval. |
| [0002-feedback-urbs-batched](patches/0002-feedback-urbs-batched.patch) | Reduces USB interrupts: feedback URBs carry several feedback packets. |

## Rebuilding the module

On an x86-64 Linux machine with the usual kernel build tools:

```
bash build.sh
```

It downloads the kernel.org source and Arch's `linux-headers 7.3.5.arch1-1`, applies `patches/` in name order and
writes `out/snd-usb-audio.ko`. On AA Signature Suite for Linux the module is installed as
`/usr/lib/modules/7.3.5-arch1-1/updates/aa-image/snd-usb-audio.ko`.

## Licence

The patches and the module are licensed under the GNU General Public License version 2
(see [LICENSE](LICENSE)), the licence of the Linux kernel's `sound/usb` driver.
The AA Signature Suite programs (Renderer, Media Server, System) are AA Audio's own and not part of this repository.
