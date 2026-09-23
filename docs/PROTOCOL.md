# Link-6 register protocol

MCU is master. FPGA is a SPI Mode 0 slave. 16-bit frames on the four
config pins after the bitstream is resident.

```
CPOL = 0, CPHA = 0
MSB first
CS_N active low
One register access = 16 SCK edges while CS_N is low
```

## Frame

```
 bit 15      14 ...... 8      7 .............. 0
+--------+---------------+----------------------+
|   W    |    ADDR[6:0]  |       DATA[7:0]      |
+--------+---------------+----------------------+
```

W=1 write. W=0 read. MISO driven only while CS_N is low.
Keep host SCK at 1 MHz until scoped.

## Sideband

IRQ: level high when STATUS & IRQ_MASK is nonzero.
TRIG: rising edge arms the pulse sampler.

## Registers

| Addr | Name | Access | Reset | Meaning |
|---|---|---|---|---|
| 0x00 | ID | R | 0xE6 | magic |
| 0x01 | VER | R | 0x10 | 1.0 |
| 0x02 | CAPS | R | 0x07 | pwm+uart+sampler |
| 0x03 | STATUS | R | 0 | bit0 rx_ready, bit1 tx_busy, bit2 rx_overrun, bit3 smp_ready, bit4 smp_armed |
| 0x04 | IRQ_MASK | R/W | 0x09 | default rx_ready + smp_ready |
| 0x05 | CTRL | R/W | 0x01 | bit0 core, bit1 led_force, bit2 pwm, bit3 uart, bit4 smp |
| 0x10 | PWM_PERIOD_LO | R/W | 0xE8 | period clocks, little-endian with 0x11 |
| 0x11 | PWM_PERIOD_HI | R/W | 0x03 | default period 1000 |
| 0x12 | PWM_DUTY_LO | R/W | 0xF4 | default duty 500 |
| 0x13 | PWM_DUTY_HI | R/W | 0x01 | |
| 0x20 | UART_DIV_LO | R/W | 0xB2 | SYS_HZ/baud, default 434 = 115200 |
| 0x21 | UART_DIV_HI | R/W | 0x01 | |
| 0x22 | UART_TX | W | | queue one byte |
| 0x23 | UART_RX | R | 0 | read clears rx_ready |
| 0x30 | SMP_CTRL | R/W | 0 | bit0 ARM, bit1 RST |
| 0x31 | SMP_WIDTH_LO | R | 0 | |
| 0x32 | SMP_WIDTH_HI | R | 0 | |
| 0x33 | SMP_PERIOD_LO | R | 0 | |
| 0x34 | SMP_PERIOD_HI | R | 0 | read clears smp_ready |

## Host sequence

1. Flash bitstream with Vicharak helper.
2. Take SPI pins as Link-6.
3. Read ID until 0xE6.
4. Write CTRL. Poll STATUS or wait on IRQ.
