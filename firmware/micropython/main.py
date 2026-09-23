"""Bring-up script. Flash the bitstream first, then run this.

    import shrike
    shrike.flash("edgekit.bin")

Then copy link6.py + this file onto the board and reset.
"""
from link6 import Link6, REG_CTRL, REG_STATUS, REG_VER, REG_CAPS

CTRL_CORE = 1 << 0
CTRL_LED = 1 << 1
CTRL_PWM = 1 << 2
CTRL_UART = 1 << 3
CTRL_SMP = 1 << 4


def main():
    bus = Link6()
    if not bus.ping():
        print("no FPGA ID - bitstream missing or IO planner skipped GPIO3-6")
        return

    ver = bus.read(REG_VER)
    caps = bus.read(REG_CAPS)
    print("link6 id=E6 ver=%d.%d caps=%02x" % (ver >> 4, ver & 0xF, caps))

    bus.write(REG_CTRL, CTRL_CORE | CTRL_PWM | CTRL_UART | CTRL_SMP | CTRL_LED)
    bus.set_pwm(1000, 0.25)   # 1 kHz, 25 % on FPGA GPIO14 + onboard LED
    bus.set_baud(115200)
    bus.uart_write(ord("K"))
    bus.arm_sampler()

    print("status=%02x irq=%d" % (bus.read(REG_STATUS), bus.irq.value()))
    print("pwm running. scope GPIO14 or watch the FPGA LED.")


if __name__ == "__main__":
    main()
