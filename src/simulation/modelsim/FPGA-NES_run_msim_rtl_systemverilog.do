transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/main_clkgen.v}
vlog -vlog01compat -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/nes_clkgen.v}
vlog -vlog01compat -work work +incdir+C:/dev/FPGA-NES/src/db {C:/dev/FPGA-NES/src/db/main_clkgen_altpll.v}
vlog -vlog01compat -work work +incdir+C:/dev/FPGA-NES/src/db {C:/dev/FPGA-NES/src/db/nes_clkgen_altpll.v}
vlib toplevel_soc
vmap toplevel_soc toplevel_soc
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/toplevel_soc.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_reset_controller.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_reset_synchronizer.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_avalon_st_adapter_006.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_avalon_st_adapter.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_sc_fifo.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_usb_rst.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_usb_gpx.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_timer_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_sysid_qsys_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_spi_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_sdram_pll.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_sdram.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0_cpu.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0_cpu_debug_slave_sysclk.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0_cpu_debug_slave_tck.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0_cpu_debug_slave_wrapper.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_nios2_gen2_0_cpu_test_bench.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_leds_pio.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_keycode.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_key.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_jtag_uart_0.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_csr.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_clk_cnt.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_condt_det.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_condt_gen.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_fifo.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_mstfsm.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_rxshifter.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_txshifter.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_spksupp.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_i2c_txout.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_hex_digits_pio.v}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/VGA_controller.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/HexDriver.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/SYS_RAM.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/synchronizers.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/PRG_ROM.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/PPU.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/CHR_ROM.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/VRAM.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_irq_mapper.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_avalon_st_adapter_006_error_adapter_0.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_avalon_st_adapter_error_adapter_0.sv}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_st_handshake_clock_crosser.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_avalon_st_clock_crosser.v}
vlog -vlog01compat -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_std_synchronizer_nocut.v}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_width_adapter.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_burst_uncompressor.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_rsp_mux_001.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_arbitrator.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_rsp_mux.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_rsp_demux_001.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_rsp_demux.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_cmd_mux_001.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_cmd_mux.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_cmd_demux_001.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_cmd_demux.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_burst_adapter.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_burst_adapter_uncmpr.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_router_008.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_router_003.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_router_002.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_router_001.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/toplevel_soc_mm_interconnect_0_router.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_slave_agent.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_master_agent.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_slave_translator.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/altera_merlin_master_translator.sv}
vlog -sv -work toplevel_soc +incdir+C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules {C:/dev/FPGA-NES/src/toplevel_soc/synthesis/submodules/ROM_PRGMR.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/CPU_2A03.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/NES_ARCHITECTURE.sv}
vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/toplevel.sv}
vcom -93 -work work {C:/dev/FPGA-NES/src/t65/T65_Pack.vhd}
vcom -93 -work work {C:/dev/FPGA-NES/src/t65/T65_ALU.vhd}
vcom -93 -work work {C:/dev/FPGA-NES/src/t65/T65_MCode.vhd}
vcom -93 -work work {C:/dev/FPGA-NES/src/t65/T65.vhd}

vlog -sv -work work +incdir+C:/dev/FPGA-NES/src {C:/dev/FPGA-NES/src/testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L toplevel_soc -voptargs="+acc"  testbench

add wave *
view structure
view signals
run -all
