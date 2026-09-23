"""Sanity-parse firmware/c/link6.h so the C contract cannot drift silently."""
import re
import unittest
from pathlib import Path

HDR = Path(__file__).resolve().parents[1] / "firmware" / "c" / "link6.h"


class HeaderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = HDR.read_text()

    def _define(self, name):
        m = re.search(rf"#define\s+{name}\s+(\S+)", self.text)
        self.assertIsNotNone(m, name)
        return m.group(1).rstrip("u")

    def test_pins_match_vicharak(self):
        self.assertEqual(self._define("LINK6_PIN_PWR"), "12")
        self.assertEqual(self._define("LINK6_PIN_EN"), "13")
        self.assertEqual(self._define("LINK6_PIN_SCK"), "2")
        self.assertEqual(self._define("LINK6_PIN_CS"), "1")
        self.assertEqual(self._define("LINK6_PIN_MOSI"), "3")
        self.assertEqual(self._define("LINK6_PIN_MISO"), "0")
        self.assertEqual(self._define("LINK6_PIN_IRQ"), "14")
        self.assertEqual(self._define("LINK6_PIN_TRIG"), "15")

    def test_id_and_clock(self):
        self.assertEqual(self._define("LINK6_ID_MAGIC"), "0xE6")
        self.assertEqual(self._define("LINK6_SYS_HZ"), "50000000")


if __name__ == "__main__":
    unittest.main()
