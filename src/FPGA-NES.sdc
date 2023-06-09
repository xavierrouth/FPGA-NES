#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "50.0 MHz" [get_ports MAX10_CLK1_50]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks -create_base_clocks

create_generated_clock -divide_by 12 -source [get_nodes *MCLK*] -name {clock_divider:cpuclkgen|clock_out} 
create_generated_clock -divide_by 4 -source [get_nodes *MCLK*] -name {clock_divider:ppuclkgen|clock_out}
create_generated_clock -divide_by 2 -source [get_nodes *MCLK*] -name {clock_divider:vgaclkgen|clock_out}
 



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************

# suppose +- 100 ps skew
# Board Delay (Data) + Propagation Delay - Board Delay (Clock)
# max 5.4(max) +0.4(trace delay) +0.1 = 5.9
# min 2.7(min) +0.4(trace delay) -0.1 = 3.0
set_input_delay -max -clock clk_dram_ext 5.9 [get_ports DRAM_DQ*]
set_input_delay -min -clock clk_dram_ext 3.0 [get_ports DRAM_DQ*]

#shift-window
set_multicycle_path -from [get_clocks {clk_dram_ext}] \
                    -to [get_clocks { u0|altpll_0|sd1|pll7|clk[0] }] \
						  -setup 2
						  
#**************************************************************
# Set Output Delay
#**************************************************************
# suppose +- 100 ps skew
# max : Board Delay (Data) - Board Delay (Clock) + tsu (External Device)
# min : Board Delay (Data) - Board Delay (Clock) - th (External Device)
# max 1.5+0.1 =1.6
# min -0.8-0.1 = 0.9
set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]

#=====================False Paths===============
set_false_path -from [get_pins -compatibility_mode *T65:CPU*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *hex_num*]
set_false_path -from [get_pins -compatibility_mode *d_writedata*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *PRG_ROM*]
set_false_path -from [get_pins -compatibility_mode *d_writedata*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *CHR_ROM*]
set_false_path -from [get_pins -compatibility_mode *ROM_PRGMR*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *PRG_ROM*]
set_false_path -from [get_pins -compatibility_mode *ROM_PRGMR*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *CHR_ROM*]
set_false_path -from [get_pins -compatibility_mode *pushbuttons*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *]
set_false_path -from [get_registers *soc_keycode*] -through [get_pins -compatibility_mode *] -to [get_registers *CONTROLLER:playerone*]
set_false_path -from [get_pins -compatibility_mode *ROM_PRGMR*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *NES_ARCHITECUTRE:NES*]
#set_false_path -from [get_pins -compatibility_mode *ROM_PRGMR*] -through [get_pins -compatibility_mode *] -to [get_pins -compatibility_mode *sld_signaltap*]

