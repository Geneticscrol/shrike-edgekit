# Contributing

This is a small timing-core kit for one board family. Keep it that way.

1. Do not add seeker, tracker, guidance, or munition language. Timing cores
   only.
2. Pin numbers come from Vicharak's published interconnect. If the board
   rev changes, update `docs/PINS.md` and the firmware headers in the same
   commit.
3. Every new output pad on the SLG47910 needs an `_oe` net. If you forget
   it, the pad floats.
4. New registers go in `docs/PROTOCOL.md` first, then `rtl/regs.v`, then
   both firmware bindings, then a test.
5. Run `make test-py`. Run `make test-rtl` if you have Icarus.
