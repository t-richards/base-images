# Base images

This repository contains Packer templates for building Tom's custom OS images.

## Requirements

 - Packer `>= 1.8.3`
 - `qemu-user-static-binfmt` (for building ARM images on x86_64)

## Getting started

```sh-session
# Build images.
$ ./script/build

<snip>

==> Wait completed after 3 minutes 32 seconds

==> Builds finished. The artifacts of successful builds are:
--> tailscale-raspios.arm-image.raspios: tailscale-raspios.img
```

## Notes

 - `tailscale-raspios`: A Raspberry Pi OS Lite image with Tailscale pre-installed.
 - `adguard-raspios`: A Raspberry Pi OS Lite image with AdGuard Home pre-installed.

## License

Copyright (c) 2025 Tom Richards. All rights reserved.
