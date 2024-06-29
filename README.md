# Base images

This repository contains Packer templates for building Tom's custom OS images.

## Requirements

 - Packer `>= 1.8.3`
 - `qemu-user-static-binfmt` (for building ARM images on x86_64)

## Getting started

```bash
./script/build
```

## Notes

 - `tailscale-raspios`: A Raspberry Pi OS Lite image with Tailscale pre-installed.

## License

Copyright (c) 2024 Tom Richards. All rights reserved.
