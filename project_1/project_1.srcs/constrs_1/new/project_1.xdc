# ==============================================================================
# Nexys A7-100T Constraints - fpga_top.v i�in
# ==============================================================================

# ==============================================================================
# PARAMETER OVERRIDE: Sim�lasyon 40 MHz, FPGA 100 MHz
# ==============================================================================


# ==============================================================================
# Clock ve Reset
# ==============================================================================
# 100MHz System Clock (E3 pini)
set_property PACKAGE_PIN E3 [get_ports M100_clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports M100_clk_i]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports M100_clk_i]

# Reset Button (Center button BTNC - N17)
set_property PACKAGE_PIN N17 [get_ports reset_i]
set_property IOSTANDARD LVCMOS33 [get_ports reset_i]
set_property PULLDOWN true [get_ports reset_i]

# ==============================================================================
# UART Interface
# ==============================================================================
# UART TX (FPGA -> PC, D4 pini)
set_property PACKAGE_PIN D4 [get_ports tx_o]
set_property IOSTANDARD LVCMOS33 [get_ports tx_o]

# UART RX (PC -> FPGA, C4 pini)
set_property PACKAGE_PIN C4 [get_ports rx_i]
set_property IOSTANDARD LVCMOS33 [get_ports rx_i]

# ==============================================================================
# LEDs (Debug)
# ==============================================================================
set_property PACKAGE_PIN H17 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led1]

set_property PACKAGE_PIN K15 [get_ports led2]
set_property IOSTANDARD LVCMOS33 [get_ports led2]

set_property PACKAGE_PIN R18 [get_ports led4]
set_property IOSTANDARD LVCMOS33 [get_ports led4]

# ==============================================================================
# Configuration Settings
# ==============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ==============================================================================
# Timing Constraints
# ==============================================================================
set_false_path -from [get_ports reset_i]
set_false_path -from [get_ports rx_i]
set_false_path -to [get_ports tx_o]
set_false_path -to [get_ports {led1 led2 led4}]