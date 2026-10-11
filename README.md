# OrangeFox for Infinix X6885

Unofficial OrangeFox Recovery device tree for Android 16 on the MediaTek MT6789 platform.

## Device Information

| Item | Value |
| --- | --- |
| Device | `Infinix X6885` |
| Platform | `MT6789` |
| Architecture | `ARM64` |
| Android Version | `Android 16` |
| SDK Version | `36` |
| Vendor Security Patch | `2026-08-01` |
| Kernel Module ABI | `6.12.38-android16-5-gcc51d883045d-4k` |
| Platform Modules | `234 modules + 5 stock metadata files` |

## Build Instructions

1. Fork this repository.
2. Open the **Actions** tab in your fork.
3. Select **Recovery Build 14.1**.
4. Click **Run workflow**.
5. Configure the workflow inputs as needed.

### Workflow Configuration

| Input | Default Value |
| --- | --- |
| `SYNC_URL` | `https://gitlab.com/OrangeFox/sync.git` |
| `MANIFEST_BRANCH` | `14.1` |
| `DEVICE_TREE_URL` | `https://github.com/sushtrsh/x6885_a16   (change to your repo url fork)` |
| `DEVICE_TREE_BRANCH` | `main` |
| `DEVICE_PATH` | `device/infinix/X6885` |
| `MAKEFILE_NAME` | `fox_X6885` |
| `BUILD_TARGET` | `vendorboot` |
| `Use ccache` | `yes` |

The default configuration targets OrangeFox Recovery 14.1 for the Infinix X6885.

## Disclaimer

This is an **unofficial device tree**. Builds are provided as-is, without any guarantee of stability or compatibility.

**DWYOR (Do With Your Own Risk).**

Always back up your stock firmware and ensure you have a reliable recovery method before flashing. Flashing custom recovery images may cause bootloops, data loss, or device bricking.
