## Linux driver porting guide for Adaps Photonics ADS6401 / ADS6401S dToF sensors
([Chinese version](README_zh_CN.md))

This repository has two driver release packages. They are for different modules. Do not mix them in one kernel config.

| | ADS6401 | ADS6401S |
| --- | --- | --- |
| Module | Spot, Small Flood, Big FoV, Big FoV V2 | Big FoV Smart, with a built-in MCU |
| Module type macro | `ADS6401_MODULE_SPOT` / `SMALL_FLOOD` / `BIG_FOV_FLOOD` / `BIG_FOV_FLOOD_V2` | `ADS6401_MODULE_BIG_FOV_FLOOD_SMART` (0x6401E) |
| This release | `ads6401_linux_driver_code_v4.1.0_LM20261009A_20261009122451.zip` | `ads6401s_linux_driver_code_v1.2.0_LM20261009A_20261009122327.zip` |
| Driver directory | `drivers/media/i2c/ads6401_drv/` | `drivers/media/i2c/ads6401s_drv/` |
| Kernel config | `CONFIG_VIDEO_ADS6401` | `CONFIG_VIDEO_ADS6401S` |
| Reference I2C | i2c4, sensor address 0x5e, compatible `adaps,ads6401` | i2c4, module MCU address 0x22, compatible `adaps,ads6401s-mbox` |
| misc device node | `/dev/ads6401_misc` | `/dev/ads6401_misc` (same name as ads6401) |
| Details | [Linux_Driver_porting_guide_4_ads6401.md](Linux_Driver_porting_guide_4_ads6401.md) | [Linux_Driver_porting_guide_4_ads6401s.md](Linux_Driver_porting_guide_4_ads6401s.md) |

The timestamp in the zip file name changes. Use the file that is actually in the repository. Driver version is the `Version` line in sysfs `info`: `4.1.0_LM20261009A` for ads6401, `1.2.0_LM20261009A` for ads6401s.

### Note
1. The driver is tied to the hardware. The release package is a reference. Please read the source and change the build switches for your own board.
2. Do not enable `CONFIG_VIDEO_ADS6401` and `CONFIG_VIDEO_ADS6401S` in the same kernel config.


#### 1. Download the latest driver release package and the build tools from GitHub

[Ads6401_Linux_Driver](https://github.com/David1934/Ads6401_Linux_Driver)

How to pack the Rockchip kernel Image into boot.img: [Build_boot_image_for_rockchip_Linux.md](Build_boot_image_for_rockchip_Linux.md).


#### 2. Hardware and software environment of the reference design
- **Target platform**: Rockchip RK3568 SoC
- **Kernel version**: Linux 5.10.110
- **SDK**: Linux 5.10 SDK based on RK3568


#### 3. What is inside a release package
Each zip has two trees:
- `<rockchip_original>`: original files from the RK3568 Linux 5.10 SDK
- `<adaps_modified>`: files we modified or added

From this release, the driver is no longer dropped into `drivers/media/i2c/` as loose `.c` files. Each sensor has its own directory. ads6401 also needs `ads6401_build_options.h` (module type is selected at the top of that file). ads6401s also needs `ads6401s_build_options.h` and `ads6401s_common.h`.

`drivers/media/i2c/Kconfig` and `Makefile` in the package come from our full kernel tree and still source other sensors. Do not overwrite your SDK files with them. Merge only the two lines for the driver you are porting. The snippets are in the two porting guides above.


#### 4. What changed for the application, compared with the previous document
`adaps_dtof_module_static_data` in `adaps_dtof_uapi.h` now has `module_type`. The misc ioctl `ADAPS_GET_DTOF_MODULE_STATIC_DATA` fills it with one of the `ADS6401_MODULE_*` values in `adaps_types.h`. Check `module_type` before parsing the EEPROM data from mmap.

The ads6401 package defaults to `ADS6401_MODULE_BIG_FOV_FLOOD_V2`. Change `SWIFT_MODULE_TYPE` in `ads6401_drv/ads6401_build_options.h` if you have another ads6401 module. ads6401s is fixed to `ADS6401_MODULE_BIG_FOV_FLOOD_SMART`. Any other value fails the build.

sysfs `status` prints `Ads6401 module type:` in hex, for example `6401D` on the default ads6401 build and `6401E` on ads6401s. sysfs `config` prints the name, for example `Big_FoV_Flood_V2` or `Big_FoV_Flood_Smart`.
