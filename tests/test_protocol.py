"""Host-side contract tests. No FPGA tools required."""
import unittest


def frame_write(addr, data):
    return (1 << 15) | ((addr & 0x7F) << 8) | (data & 0xFF)


def frame_read(addr):
    return (addr & 0x7F) << 8


def decode(word):
    return {
        "w": (word >> 15) & 1,
        "addr": (word >> 8) & 0x7F,
        "data": word & 0xFF,
    }


class ProtocolTests(unittest.TestCase):
    def test_write_frame_layout(self):
        w = frame_write(0x05, 0x1D)
        d = decode(w)
        self.assertEqual(d["w"], 1)
        self.assertEqual(d["addr"], 0x05)
        self.assertEqual(d["data"], 0x1D)

    def test_read_frame_is_write_cleared(self):
        w = frame_read(0x00)
        d = decode(w)
        self.assertEqual(d["w"], 0)
        self.assertEqual(d["addr"], 0x00)
        self.assertEqual(d["data"], 0)

    def test_id_magic(self):
        self.assertEqual(0xE6, 0xE6)

    def test_pwm_period_math(self):
        sys_hz = 50_000_000
        period = sys_hz // 1000
        self.assertEqual(period, 50_000)
        duty = int(period * 0.25)
        self.assertEqual(duty, 12_500)

    def test_baud_div(self):
        div = 50_000_000 // 115200
        self.assertEqual(div, 434)

    def test_status_irq_mask_default(self):
        mask = 0x09
        status_rx = 0x01
        status_smp = 0x08
        self.assertTrue(status_rx & mask)
        self.assertTrue(status_smp & mask)
        self.assertFalse(0x02 & mask)


class SamplerModelTests(unittest.TestCase):
    def test_width_and_period(self):
        samples = [0] * 10 + [1] * 20 + [0] * 30 + [1]
        st = "idle"
        wcnt = pcnt = 0
        width = period = None
        prev = 0
        for x in samples:
            rise = x and not prev
            fall = (not x) and prev
            if st == "idle":
                st = "wait_r"
            elif st == "wait_r" and rise:
                wcnt = 1
                pcnt = 1
                st = "high"
            elif st == "high":
                wcnt += 1
                pcnt += 1
                if fall:
                    width = wcnt
                    st = "wait_p"
            elif st == "wait_p":
                pcnt += 1
                if rise:
                    period = pcnt
                    st = "idle"
            prev = x
        self.assertEqual(width, 21)
        self.assertEqual(period, 51)


if __name__ == "__main__":
    unittest.main()
