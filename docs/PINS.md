# Pin map — Vicharak Shrike family

Source: https://vicharak-in.github.io/shrike/shrike_pinouts.html

All I/O is 3.3 V. Do not drive 5 V into any header.

## Power / config (always reserved)

| Role | FPGA | Shrike / Shrike-lite (RP2040 / RP2350) | Shrike-fi (ESP32-S3) |
|---|---|---|---|
| FPGA PWR | PWR | GPIO 12 | GPIO 8 |
| FPGA EN  | EN  | GPIO 13 | GPIO 9 |

## Link-6 after bitstream load

The PCB is an 8-wire MCU-FPGA bundle: PWR + EN + 6 IO. Four of the six IO
pins are the ForgeFPGA configuration SPI and then become GPIO.

| Link-6 signal | Direction after config | FPGA GPIO | RP2040 / RP2350 | ESP32-S3 | Dual-use during config |
|---|---|---|---|---|---|
| SCK  | MCU to FPGA | 3  | GPIO 2  | GPIO 12 | SPI_SCLK |
| CS_N | MCU to FPGA | 4  | GPIO 1  | GPIO 10 | SPI_SS   |
| MOSI | MCU to FPGA | 5  | GPIO 3  | GPIO 11 | SPI_SI   |
| MISO | FPGA to MCU | 6  | GPIO 0  | GPIO 13 | SPI_SO   |
| IRQ  | FPGA to MCU | 18 | GPIO 14 | (header) | user GPIO |
| TRIG | MCU to FPGA | 17 | GPIO 15 | (header) | user GPIO |

## On-board LEDs (active high)

| LED | Pin |
|---|---|
| MCU user LED | RP: GPIO 4 / ESP32-S3: GPIO 21 |
| FPGA user LED | FPGA GPIO 16 (map led + led_oe) |

## Internal oscillator

| Verilog port | ForgeFPGA pad |
|---|---|
| clk | OSC_CLK |
| clk_en | OSC_EN |

Internal OSC is 50 MHz = SYS_HZ.

## Default user pads in rtl/top.v

| Port | FPGA GPIO |
|---|---|
| pwm_out | 14 |
| uart_tx | 8 |
| uart_rx | 9 |
| smp_in | 10 |
| led | 16 |

Do not steal GPIO 3/4/5/6/17/18. Those are Link-6.
