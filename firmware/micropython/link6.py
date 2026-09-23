"""Link-6 host for Vicharak Shrike (RP2040 / RP2350).

Bit-bangs SPI Mode 0 on the published interconnect. Keep SCK ~100 kHz
until you have a working ID read; then raise it.
"""
from machine import Pin
import time

PIN_PWR = 12
PIN_EN = 13
PIN_SCK = 2
PIN_CS = 1
PIN_MOSI = 3
PIN_MISO = 0
PIN_IRQ = 14
PIN_TRIG = 15
PIN_MCU_LED = 4

REG_ID = 0x00
REG_VER = 0x01
REG_CAPS = 0x02
REG_STATUS = 0x03
REG_IRQ_MASK = 0x04
REG_CTRL = 0x05
REG_PWM_PERIOD_LO = 0x10
REG_PWM_PERIOD_HI = 0x11
REG_PWM_DUTY_LO = 0x12
REG_PWM_DUTY_HI = 0x13
REG_UART_DIV_LO = 0x20
REG_UART_DIV_HI = 0x21
REG_UART_TX = 0x22
REG_UART_RX = 0x23
REG_SMP_CTRL = 0x30
REG_SMP_WIDTH_LO = 0x31
REG_SMP_WIDTH_HI = 0x32
REG_SMP_PERIOD_LO = 0x33
REG_SMP_PERIOD_HI = 0x34

ID_MAGIC = 0xE6
SYS_HZ = 50_000_000


class Link6:
    def __init__(self, half_period_us=5):
        self.half = half_period_us
        self.pwr = Pin(PIN_PWR, Pin.OUT, value=1)
        self.en = Pin(PIN_EN, Pin.OUT, value=1)
        self.sck = Pin(PIN_SCK, Pin.OUT, value=0)
        self.cs = Pin(PIN_CS, Pin.OUT, value=1)
        self.mosi = Pin(PIN_MOSI, Pin.OUT, value=0)
        self.miso = Pin(PIN_MISO, Pin.IN)
        self.irq = Pin(PIN_IRQ, Pin.IN)
        self.trig = Pin(PIN_TRIG, Pin.OUT, value=0)
        self.led = Pin(PIN_MCU_LED, Pin.OUT, value=0)

    def _tick(self):
        time.sleep_us(self.half)

    def xfer16(self, word):
        result = 0
        self.cs.value(0)
        self._tick()
        for i in range(15, -1, -1):
            self.mosi.value((word >> i) & 1)
            self._tick()
            self.sck.value(1)
            self._tick()
            result = (result << 1) | self.miso.value()
            self.sck.value(0)
        self._tick()
        self.cs.value(1)
        self._tick()
        return result

    def write(self, addr, data):
        word = (1 << 15) | ((addr & 0x7F) << 8) | (data & 0xFF)
        self.xfer16(word)

    def read(self, addr):
        word = ((addr & 0x7F) << 8)
        return self.xfer16(word) & 0xFF

    def ping(self, tries=20):
        for _ in range(tries):
            if self.read(REG_ID) == ID_MAGIC:
                return True
            time.sleep_ms(10)
        return False

    def write16(self, lo_addr, value):
        self.write(lo_addr, value & 0xFF)
        self.write(lo_addr + 1, (value >> 8) & 0xFF)

    def read16(self, lo_addr):
        return self.read(lo_addr) | (self.read(lo_addr + 1) << 8)

    def set_pwm(self, freq_hz, duty_frac):
        if freq_hz <= 0:
            raise ValueError("freq")
        period = max(1, int(SYS_HZ / freq_hz))
        if period > 0xFFFF:
            raise ValueError("freq too low for 16-bit period")
        duty = int(period * duty_frac)
        if duty > 0xFFFF:
            duty = 0xFFFF
        self.write16(REG_PWM_PERIOD_LO, period)
        self.write16(REG_PWM_DUTY_LO, duty)

    def set_baud(self, baud):
        div = max(1, int(SYS_HZ / baud))
        if div > 0xFFFF:
            raise ValueError("baud too low")
        self.write16(REG_UART_DIV_LO, div)

    def uart_write(self, byte):
        self.write(REG_UART_TX, byte & 0xFF)

    def uart_read(self):
        return self.read(REG_UART_RX)

    def arm_sampler(self):
        self.write(REG_SMP_CTRL, 0x01)

    def pulse_trig(self):
        self.trig.value(1)
        time.sleep_us(20)
        self.trig.value(0)

    def read_sample(self):
        width = self.read16(REG_SMP_WIDTH_LO)
        period = self.read16(REG_SMP_PERIOD_LO)
        return width, period
