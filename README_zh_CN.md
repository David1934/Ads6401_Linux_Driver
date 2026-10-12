## **灵明光子 ADS6401 / ADS6401S dToF 传感器 Linux 驱动移植指南**
([English version](README.md))

本仓库给客户的内容有两套驱动发布包，对应两种模组，不要混用。

| | ADS6401 | ADS6401S |
| --- | --- | --- |
| 模组 | Spot、Small Flood、Big FoV、Big FoV V2 | 大 FoV Smart，内置 MCU |
| 模组类型宏 | `ADS6401_MODULE_SPOT` / `SMALL_FLOOD` / `BIG_FOV_FLOOD` / `BIG_FOV_FLOOD_V2` | `ADS6401_MODULE_BIG_FOV_FLOOD_SMART`（0x6401E） |
| 本次发布包 | `ads6401_linux_driver_code_v4.1.0_LM20261009A_20261009122451.zip` | `ads6401s_linux_driver_code_v1.2.0_LM20261009A_20261009122327.zip` |
| 驱动目录 | `drivers/media/i2c/ads6401_drv/` | `drivers/media/i2c/ads6401s_drv/` |
| 内核配置 | `CONFIG_VIDEO_ADS6401` | `CONFIG_VIDEO_ADS6401S` |
| 样机 I2C | i2c4，sensor 地址 0x5e，compatible `adaps,ads6401` | i2c4，模组 MCU 地址 0x22，compatible `adaps,ads6401s-mbox` |
| misc 设备节点 | `/dev/ads6401_misc` | `/dev/ads6401_misc`（名字和 ads6401 相同） |
| 详细步骤 | [Linux_Driver_porting_guide_4_ads6401.md](Linux_Driver_porting_guide_4_ads6401.md) | [Linux_Driver_porting_guide_4_ads6401s.md](Linux_Driver_porting_guide_4_ads6401s.md) |

zip 文件名里的时间戳会变，以仓库里实际文件为准。驱动版本看 `info` 里的 `Version`：ads6401 是 `4.1.0_LM20261009A`，ads6401s 是 `1.2.0_LM20261009A`。

### 特别提醒
1. 驱动程序跟硬件电路紧密相关，我们的驱动发布包仅供参考，客户应在充分理解驱动源码后，根据自己实际的硬件环境进行适当的修改（包括一些编译开关的配置）
2. 同一份内核配置里不要同时打开 `CONFIG_VIDEO_ADS6401` 和 `CONFIG_VIDEO_ADS6401S`


#### 1. 从 github 下载最新的驱动发布包和编译工具包

[Ads6401_Linux_Driver](https://github.com/David1934/Ads6401_Linux_Driver)

Rockchip 平台上把 kernel Image 打成 boot.img 的步骤见 [编译Rockchip的Linux kernel镜像并生成boot.img](Build_boot_image_for_rockchip_Linux.md)。


#### 2. 参考设计的硬件软件环境
- **目标平台**：Rockchip RK3568 SoC
- **内核版本**：Linux 5.10.110
- **SDK包**：基于 RK3568 的 Linux 5.10 SDK


#### 3. 发布包里的目录
每个 zip 解压后都是两份对照：
- `<rockchip_original>`：Rk3568 Linux 5.10 SDK 上原始的源文件
- `<adaps_modified>`：我们改过和新增的文件

从这一版起，驱动不再放在 `drivers/media/i2c/` 根目录，而是各自一个子目录。ads6401 还要带上 `ads6401_build_options.h`（模组类型在这个文件开头选）。ads6401s 还要带上 `ads6401s_build_options.h` 和 `ads6401s_common.h`。

发布包里的 `drivers/media/i2c/Kconfig`、`Makefile` 是我们整棵内核树上的文件，里面还 source 了其它传感器。移植时不要整文件覆盖，只合入自己这份驱动对应的两行，具体片段写在上面两个移植指南里。


#### 4. 和上一版文档相比，应用层要看的变化
`adaps_dtof_uapi.h` 的 `adaps_dtof_module_static_data` 增加了 `module_type`。misc 设备 ioctl `ADAPS_GET_DTOF_MODULE_STATIC_DATA` 会填这个字段，取值就是 `adaps_types.h` 里的 `ADS6401_MODULE_*`。上层先看 `module_type`，再解析 mmap 出来的 EEPROM。

ads6401 当前发布包默认是 `ADS6401_MODULE_BIG_FOV_FLOOD_V2`，在 `ads6401_drv/ads6401_build_options.h` 里改 `SWIFT_MODULE_TYPE`。ads6401s 固定是 `ADS6401_MODULE_BIG_FOV_FLOOD_SMART`，改成别的值编不过。

sysfs 的 `status` 里有一行 `Ads6401 module type:`，打印的是这个值的十六进制，例如 ads6401 默认 `6401D`，ads6401s 是 `6401E`。`config` 里的 `ADS6401_MODULE_TYPE` 是名字字符串，例如 `Big_FoV_Flood_V2`、`Big_FoV_Flood_Smart`。
