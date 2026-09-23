# Host tests always. RTL tests if iverilog is on PATH.
PYTHON ?= python3
IVERILOG ?= $(shell command -v iverilog 2>/dev/null)
RTL = rtl/sync2.v rtl/link6_spi_slave.v rtl/pwm_ch.v rtl/uart_tx.v rtl/uart_rx.v rtl/pulse_sampler.v rtl/regs.v rtl/top.v

.PHONY: test test-py test-rtl clean

test: test-py test-rtl

test-py:
	$(PYTHON) -m unittest discover -s tests -v

test-rtl:
ifeq ($(IVERILOG),)
	@echo "iverilog not installed - skipping RTL benches"
else
	$(IVERILOG) -o /tmp/tb_pwm.vvp rtl/pwm_ch.v sim/tb_pwm.v && vvp /tmp/tb_pwm.vvp
	$(IVERILOG) -o /tmp/tb_smp.vvp rtl/sync2.v rtl/pulse_sampler.v sim/tb_sampler.v && vvp /tmp/tb_smp.vvp
	$(IVERILOG) -o /tmp/tb_uart.vvp rtl/sync2.v rtl/uart_tx.v rtl/uart_rx.v sim/tb_uart.v && vvp /tmp/tb_uart.vvp
endif

clean:
	rm -f *.vcd *.vvp /tmp/tb_*.vvp
