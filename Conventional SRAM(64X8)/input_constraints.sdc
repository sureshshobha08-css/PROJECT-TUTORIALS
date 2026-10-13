
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 2 -clock clk [get_ports chip_enable]
set_input_delay 2 -clock clk [get_ports write_enable]
set_input_delay 2 -clock clk [get_ports address]
set_input_delay 2 -clock clk [get_ports din]
set_output_delay 2 -clock clk [get_ports dout]
set_driving_cell -lib_cell BUF [all_inputs]
set_load 0.05 [all_outputs]
