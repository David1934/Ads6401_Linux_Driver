## Linux_Driver_Porting_Guide_for_Adaps_Photonics_ADS6401 dToF Sensor
([Chinese version](README_zh_CN.md))

#### 1. Download the latest driver release package and compilation tool package from GitHub

[Ads6401_Linux_Driver](https://github.com/David1934/Ads6401_Linux_Driver)

#### 2. Hardware and Software Environment for Reference Design
- **Target Platform**: Rockchip RK3568 SoC
- **Kernel Version**: Linux 5.10.110
- **SDK Package**: Linux 5.10 SDK based on RK3568. The `<rockchip_original>` directory contains the original source files from the RK3568 Linux 5.10 SDK, while `<adaps_modified>` contains the files we have modified and added.


#### 3. List of Modified and Added Files
![Modified and Added Files](vx_images/557763628949679.png)
   ```
kernel/arch/arm64/boot/dts/rockchip/rk3568-evb1-ddr4-v10-linux.dts
kernel/arch/arm64/configs/rockchip_linux_defconfig
kernel/drivers/media/i2c/ads6401.c
kernel/drivers/media/i2c/ads6401_flood.c
kernel/drivers/media/i2c/ads6401_spot.c
kernel/drivers/media/i2c/Kconfig
kernel/drivers/media/i2c/Makefile
kernel/drivers/media/platform/rockchip/cif/capture.c
kernel/drivers/media/platform/rockchip/cif/dev.c
kernel/drivers/media/platform/rockchip/cif/dev.h
kernel/include/uapi/linux/adaps_dtof_uapi.h
kernel/include/uapi/linux/adaps_types.h
kernel/include/uapi/linux/rk-camera-module.h
   ```


#### 4. Porting Steps
##### 4.1 Code Integration
1. Copy the files in the `<adaps_modified>` directory to the corresponding paths in the SDK:
   - Header files: `adaps_types.h`, `adaps_dtof_uapi.h`, `rk-camera-module.h` → Copy to `include/uapi/linux/`
   - Driver files: `ads6401*.c` → Copy to `drivers/media/i2c/`

2. Modify the I2C driver Makefile (`drivers/media/i2c/Makefile`) and add the ADS6401 driver compilation item:
   ```makefile
   # Add at an appropriate position
   obj-$(CONFIG_VIDEO_ADS6401) += ads6401.o
   ```

3. Modify the I2C driver Kconfig (`drivers/media/i2c/Kconfig`) and add the ADS6401 driver compilation item:
   ```Kconfig
   # Add at an appropriate position
   config VIDEO_ADS6401
	tristate "Adaps ADS6401 sensor support"
	depends on I2C && VIDEO_V4L2
	select V4L2_FWNODE
	help
	  This is a Video4Linux2 sensor driver for the Adaps Ads6401 camera.

	  To compile this driver as a module, choose M here: the
	  module will be called Ads6401.

   config SWIFT_MINI_DEMO_BOX
	bool "rk3568 Linux for ads6401 mini demo box"
	depends on VIDEO_ADS6401
	default n
	help
	  Enable this option to support rk3568 Linux for ads6401 mini demo box.

   ```

4. Modify the Linux kernel feature configuration option file (`arch\arm64\configs\rockchip_linux_defconfig`) and add some compilation options: (In our internal Gerrit repository, we have multiple similar files to support Hawk, Swift, and different adapter boards)
   ```
   # Add at the end of the file
   # adaps modification for swift mini-demo-box on adaps rk3568 SoC mini board
   # CONFIG_DP83720_PHY=y
   CONFIG_USB_CONFIGFS_RNDIS=y
   CONFIG_USB_U_ETHER=y
   CONFIG_USB_F_RNDIS=y
   CONFIG_VIDEO_ADS6401=y
   # The following line is only required for Adaps' miniaturized prototype
   CONFIG_SWIFT_MINI_DEMO_BOX=y
   ```

ADS6401 supports two major module types: SPOT and FLOOD (with more sub-types), which are distinguished by macro definitions in ads6401.c:
   ```
#define SWIFT_MODULE_TYPE               ADS6401_MODULE_SPOT  // ADS6401_MODULE_FLOOD
   ```


##### 4.2 Compilation and Deployment
1. Execute kernel compilation:
   ```bash
   make ARCH=arm64 rockchip_linux_defconfig
   make ARCH=arm64 -j8
   ```

2. Deploy the generated kernel image and driver modules (if configured as modules) to the RK3568 development board, and restart the board to take effect.
Rockchip's SDK has made some Android-like customized modifications to the kernel, supporting ADB. The kernel burning image file uses boot.img. The compilation script build.sh in the SDK provides a lunch menu to select different development board types, and also offers automated operations to convert the traditional kernel image file (Image) to boot.img. Customers should perform corresponding processing according to the actual platform used.


##### 4.3. Verification
- Check driver loading: `lsmod | grep ads6401` or `dmesg | grep DRV_ADS6401`
- Verify the device node: `ls /dev/ads6401_misc` (the device node of the misc driver in the ADS6401 driver)
- Verify the existence of our unique device attributes:
   ```bash
   root@rk356x:~# find /sys -name register
   /sys/devices/platform/fe5d0000.i2c/i2c-4/4-005e/register

   root@rk356x:~# cat /sys/devices/platform/fe5d0000.i2c/i2c-4/4-005e/info
   Adaps ads6401 dToF sensor driver
   Version:                       3.2.11_LM20250822A
   Build Time:                    Fri Aug 22 12:01:10 CST 2025
   I2C Bus Num:                   4
   I2C bus frequency:             1000000Hz
   I2C address for ads6401:       0x5e
   Current TTY:                   pts0
   tdc_delay_major:               0xa
   tdc_delay_minor:               0x8

   root@rk356x:~# cat /sys/devices/platform/fe5d0000.i2c/i2c-4/4-005e/config
   Build switch options:
   ---------------------------------------------------------
   MINI_DEMO_BOX:                                     No
   ADS6401_MODULE_TYPE:                               Spot
   ENABLE_BIG_FOV_MODULE:                             No
   SENSOR_XCLK_FROM_SOC:                              Yes
   IGNORE_PROBE_FAILURE:                              Yes
   ...
   NON_CONTINUOUS_MIPI_CLK:                           Yes
   MIPI_DATA_LANE_COUNT:                              2
   MIPI_SPEED:                                        1000 Mbps
   SOC_MIPI_RX_CLOCK_FREQ:                            500 MHz
   EEPROM_CHIP_CAPACITY:                              65536 bytes
   ADAPS_DBG_ONCE:                                    0x400000
   ```
