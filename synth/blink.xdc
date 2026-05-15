## blink.xdc - Basys 3 pin constraints for the Week 1 blink demo.
## Pin assignments derived from the Digilent Basys 3 Master XDC.
##
## Only two pins are constrained:
##   - clk: 100 MHz onboard oscillator (W5)
##   - led: LED[0] (U16, rightmost LED on the board)

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## LED[0]
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports led]
