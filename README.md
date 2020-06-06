### USB Sniffer

Github: [https://github.com/ultraembedded/core_usb_sniffer](https://github.com/ultraembedded/core_usb_sniffer)

This core is a HS/FS USB2.0 analyzer (USB bus sniffer).  
The core monitors a UTMI interface and logs the traffic seen to a memory buffer via an AXI-4 bus master interface.  
The log format can be extracted continuously (continuous capture mode) or the core can stop capturing when the memory buffer is full (one-shot mode).

Configuration of the IP is performed using an AXI4-Lite slave interface.

This core has been used to produce a [USB 2.0 Capture Device](https://github.com/ultraembedded/usb2sniffer).

#### Features

* Option of filtering based on device ID and/or endpoint.
* Option of filtering out SOF packets.
* Option of filtering out IN+NAK packets.
* Dense logging format.
* Supports continuous streaming or one-shot mode.
* Detection of buffer overruns.

##### Register Map

| Offset | Name | Description   |
| ------ | ---- | ------------- |
| 0x00 | USB_BUFFER_CFG | [RW] Configuration Register |
| 0x04 | USB_BUFFER_STS | [R] Status Register |
| 0x08 | USB_BUFFER_BASE | [RW] Buffer Base Address |
| 0x0c | USB_BUFFER_END | [RW] Buffer End Address |
| 0x10 | USB_BUFFER_CURRENT | [R] Buffer Current address |

##### Register: USB_BUFFER_CFG

| Bits | Name | Description    |
| ---- | ---- | -------------- |
| 31 | CONT | Continuous capture - overwrite on wrap (0 = Stop on full, 1 = cont) |
| 30:24 | DEV | Device ID to match (only if MATCH_DEV = 1) |
| 19:16 | EP | Endpoint to match (only if MATCH_EP = 1) |
| 15 | PHY_DMPULLDOWN | UTMI PHY D+ Pulldown Enable (valid if SPEED=manual) |
| 14 | PHY_DPPULLDOWN | UTMI PHY D+ Pulldown Enable (valid if SPEED=manual) |
| 13 | PHY_TERMSELECT | UTMI PHY Termination Select (valid if SPEED=manual) |
| 12:11 | PHY_XCVRSELECT | UTMI PHY Transceiver Select (valid if SPEED=manual) |
| 10:9 | PHY_OPMODE | UTMI PHY Output Mode (valid if SPEED=manual) |
| 8:7 | SPEED | USB bus speed (0 = HS, 1 = FS, 2 = LS, 3=manual) |
| 6 | EXCLUDE_EP | Exclude specific endpoint |
| 5 | MATCH_EP | Match specific endpoint |
| 4 | EXCLUDE_DEV | Exclude specific device ID |
| 3 | MATCH_DEV | Match specific device ID |
| 2 | IGNORE_SOF | Drop SOF packets (0 = Log SOF, 1 = Drop SOF) |
| 1 | IGNORE_IN_NAK | Drop IN + NAK sequences |
| 0 | ENABLED | Capture enabled |

##### Register: USB_BUFFER_STS

| Bits | Name | Description    |
| ---- | ---- | -------------- |
| 2 | DATA_LOSS | Data lost due to stream backpressure |
| 1 | WRAPPED | Capture wrapped |
| 0 | TRIG | Capture triggered |

##### Register: USB_BUFFER_BASE

| Bits | Name | Description    |
| ---- | ---- | -------------- |
| 31:0 | ADDR | Address of buffer base |

##### Register: USB_BUFFER_END

| Bits | Name | Description    |
| ---- | ---- | -------------- |
| 31:0 | ADDR | Address of buffer end |

##### Register: USB_BUFFER_CURRENT

| Bits | Name | Description    |
| ---- | ---- | -------------- |
| 31:0 | ADDR | Current buffer address - last entry written |

#### References

* [UTMI+ Low Pin Interface (ULPI) Specification](https://www.sparkfun.com/datasheets/Components/SMD/ULPI_v1_1.pdf)
* [SMSC USB3300 USB PHY Datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/3300db.pdf)
* [ULPI Wrapper](https://github.com/ultraembedded/core_ulpi_wrapper)

