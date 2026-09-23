# shrike-edgekit

MCU + FPGA edge kit for the [Vicharak Shrike](https://github.com/vicharak-in/shrike) family.

Timing cores. Not a seeker.

The public repo was created with a description and nothing else. This tree
is the actual kit: a documented 6-bit MCU-FPGA register bus on the pins
Vicharak already wired, plus PWM, UART, and a pulse sampler that fit the
Renesas SLG47910 (1120 five-input LUTs, 50 MHz internal OSC).

## What you get

| Layer | Path | What it is |
|---|---|---|
| Protocol | `docs/PROTOCOL.md` | 16-bit SPI Mode 0 frames, register map, IRQ/TRIG |
| Pins | `docs/PINS.md` | RP2040 / RP2350 / ESP32-S3 interconnect copied from the published pinout |
| RTL | `rtl/` | `link6_spi_slave`, `pwm_ch`, `uart_tx`/`uart_rx`, `pulse_sampler`, `regs`, `top` |
| IO map | `rtl/io_planner.txt` | Go Configure pad list, including every `_oe` |
| MCU | `firmware/micropython/` | bit-bang host + bring-up script |
| MCU | `firmware/c/link6.h` | same contract for Pico SDK / C |
| Tests | `tests/`, `sim/` | protocol + header lock tests; Icarus benches for PWM / UART / sampler |

## Hardware contract

Shrike / Shrike-lite expose an 8-wire MCU-FPGA bundle. Two wires are PWR and
EN. The remaining six are Link-6. Four of those six are the configuration
SPI and become the register bus after the bitstream is resident.

```
RP2040/RP2350          FPGA GPIO
GPIO 12  PWR  -------> PWR
GPIO 13  EN   -------> EN
GPIO  2  SCK  -------> 3
GPIO  1  CS_N -------> 4
GPIO  3  MOSI -------> 5
GPIO  0  MISO <------- 6
GPIO 14  IRQ  <------- 18
GPIO 15  TRIG -------> 17
```

Shrike-fi drops IRQ/TRIG from the on-PCB pair (4-bit link). Same SPI
register bus on GPIO 12/10/11/13.

Source: https://vicharak-in.github.io/shrike/shrike_pinouts.html

## Build the bitstream

1. Install Renesas Go Configure Hub, ForgeFPGA Workshop.
2. New project, device `SLG47910`.
3. Paste the files under `rtl/` into the HDL editor. `top` is the top module.
4. IO planner: follow `rtl/io_planner.txt` exactly. `clk`/`clk_en` go to
   `OSC_CLK`/`OSC_EN`. Every output has a matching `_oe`.
5. Generate bitstream. Copy `edgekit.bin` onto the board next to the
   MicroPython files.

There is no checked-in `.bin`. The vendor PnR is not reproducible from this
repo without their GUI or a headless placer like [shrike-starter](https://github.com/visejak/shrike-starter).

## Talk to it

On the official Shrike UF2:

```python
import shrike
shrike.flash("edgekit.bin")

from link6 import Link6
bus = Link6()
assert bus.ping()
bus.write(0x05, 0x1D)        # core + pwm + uart + sampler + led
bus.set_pwm(1000, 0.25)
```

`ID` must read `0xE6`. If it does not, the bitstream is not running or GPIO
3/4/5/6 were not mapped.

## Tests

```
python -m unittest discover -s tests -v
make test          # adds Icarus benches when iverilog exists
```

CI runs both.

## Limits

- 16-bit PWM period. Floor is `SYS_HZ / 65535` ~ 763 Hz. For audio-rate PWM
  raise the fabric clock via the SLG47910 PLL (not wired in this kit).
- UART is 8N1, 1x sampling. Stay at standard bauds.
- Sampler saturates at 65535 ticks (1.31 ms at 50 MHz).
- Link-6 SCK is synchronized into the 50 MHz domain. Keep host SCK <= 1 MHz
  until you have scoped it.
- LUT budget is tight if you start pasting a CPU in here. Count before you
  add.

## License

MIT. Hardware pinout documentation belongs to Vicharak; this repo only
restates the published table so the cores can be wired without guesswork.
