
module toplevel_soc (
	clk_clk,
	game_rom_conduit_rom_data,
	game_rom_conduit_prg_rom_write,
	game_rom_conduit_rom_addr,
	game_rom_conduit_chr_rom_write,
	game_rom_conduit_mirror,
	game_rom_conduit_chr_raml,
	hex_digits_export,
	i2c_0_i2c_serial_sda_in,
	i2c_0_i2c_serial_scl_in,
	i2c_0_i2c_serial_sda_oe,
	i2c_0_i2c_serial_scl_oe,
	key_external_connection_export,
	keycode_export,
	leds_export,
	master_clk_clk,
	reset_reset_n,
	sdram_clk_clk,
	sdram_wire_addr,
	sdram_wire_ba,
	sdram_wire_cas_n,
	sdram_wire_cke,
	sdram_wire_cs_n,
	sdram_wire_dq,
	sdram_wire_dqm,
	sdram_wire_ras_n,
	sdram_wire_we_n,
	spi0_MISO,
	spi0_MOSI,
	spi0_SCLK,
	spi0_SS_n,
	usb_gpx_export,
	usb_irq_export,
	usb_rst_export,
	keycode2_export);	

	input		clk_clk;
	output	[7:0]	game_rom_conduit_rom_data;
	output		game_rom_conduit_prg_rom_write;
	output	[15:0]	game_rom_conduit_rom_addr;
	output		game_rom_conduit_chr_rom_write;
	output		game_rom_conduit_mirror;
	output		game_rom_conduit_chr_raml;
	output	[15:0]	hex_digits_export;
	input		i2c_0_i2c_serial_sda_in;
	input		i2c_0_i2c_serial_scl_in;
	output		i2c_0_i2c_serial_sda_oe;
	output		i2c_0_i2c_serial_scl_oe;
	input	[1:0]	key_external_connection_export;
	output	[7:0]	keycode_export;
	output	[13:0]	leds_export;
	output		master_clk_clk;
	input		reset_reset_n;
	output		sdram_clk_clk;
	output	[12:0]	sdram_wire_addr;
	output	[1:0]	sdram_wire_ba;
	output		sdram_wire_cas_n;
	output		sdram_wire_cke;
	output		sdram_wire_cs_n;
	inout	[15:0]	sdram_wire_dq;
	output	[1:0]	sdram_wire_dqm;
	output		sdram_wire_ras_n;
	output		sdram_wire_we_n;
	input		spi0_MISO;
	output		spi0_MOSI;
	output		spi0_SCLK;
	output		spi0_SS_n;
	input		usb_gpx_export;
	input		usb_irq_export;
	output		usb_rst_export;
	output	[7:0]	keycode2_export;
endmodule
