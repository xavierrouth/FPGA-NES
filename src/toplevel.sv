typedef struct packed {
	logic [15:0] PC; // PC, not sure which it is unclear
	logic [15:0] SP; // Stack Pointer
	logic [7:0] PF; // Processor Flags
	logic [7:0] X;
	logic [7:0] Y; 
	logic [7:0] A; 
} T65_Dbg;


//-------------------------------------------------------------------------
//      ECE 385 - Summer 2021 Lab 7 Top-level                            --
//                                                                       --
//      Updated Fall 2021 as Lab 7                                       --
//      For use with ECE 385                                             --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------


module toplevel (

      ///////// Clocks /////////
      input    MAX10_CLK1_50,

      ///////// KEY /////////
      input    [ 1: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LEDR /////////
      output   logic [ 9: 0]   LEDR,

      ///////// HEX /////////
      output   [ 7: 0]   HEX0,
      output   [ 7: 0]   HEX1,
      output   [ 7: 0]   HEX2,
      output   [ 7: 0]   HEX3,
      output   [ 7: 0]   HEX4,
      output   [ 7: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// VGA /////////
      output             VGA_HS,
      output             VGA_VS,
      output   [ 3: 0]   VGA_R,
      output   [ 3: 0]   VGA_G,
      output   [ 3: 0]   VGA_B,
		
		

      ///////// ARDUINO /////////
      inout    [15: 0]   ARDUINO_IO,
      inout              ARDUINO_RESET_N 

);



//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic SPI0_CS_N, SPI0_SCLK, SPI0_MISO, SPI0_MOSI, USB_GPX, USB_IRQ, USB_RST;
	logic [3:0] hex_num_5, hex_num_4, hex_num_3, hex_num_2, hex_num_1, hex_num_0; //4 bit input hex digits
	logic [1:0] signs;
	logic [1:0] hundreds;
	logic [7:0] keycode;

//=======================================================
//  Toplevel Outside / Board Connections
//=======================================================
	
	// USB / SPI0
	
	assign ARDUINO_IO[10] = SPI0_CS_N;
	assign ARDUINO_IO[13] = SPI0_SCLK;
	assign ARDUINO_IO[11] = SPI0_MOSI;
	assign ARDUINO_IO[12] = 1'bZ;
	assign SPI0_MISO = ARDUINO_IO[12];
	
	assign ARDUINO_IO[9] = 1'bZ;
	assign USB_IRQ = ARDUINO_IO[9];
	
	//Assignments specific to Sparkfun USBHostShield-v13
	//assign ARDUINO_IO[7] = USB_RST;
	//assign ARDUINO_IO[8] = 1'bZ;
	//assign USB_GPX = ARDUINO_IO[8];
		
	//Assignments specific to Circuits At Home UHS_20
	assign ARDUINO_RESET_N = USB_RST;
	assign ARDUINO_IO[8] = 1'bZ;
	//GPX is unconnected to shield, not needed for standard USB host - set to 0 to prevent interrupt
	assign USB_GPX = 1'b0;
	
	// Hex Drivers
	
	//HEX drivers to convert numbers to HEX output
	
	HexDriver hex_driver5 (hex_num_5, HEX5[6:0]);
	assign HEX5[7] = 1'b1;
	
	HexDriver hex_driver4 (hex_num_4, HEX4[6:0]);
	assign HEX4[7] = 1'b1;
	
	HexDriver hex_driver3 (hex_num_3, HEX3[6:0]);
	assign HEX3[7] = 1'b1;
	
	HexDriver hex_driver2 (hex_num_2, HEX2[6:0]);
	assign HEX2[7] = 1'b1;
	
	HexDriver hex_driver1 (hex_num_1, HEX1[6:0]);
	assign HEX1[7] = 1'b1;
	
	HexDriver hex_driver0 (hex_num_0, HEX0[6:0]);
	assign HEX0[7] = 1'b1;
	
//=======================================================
//  I/O Synchronizers
//=======================================================

	logic syncd_reset_h;
	logic syncd_continue;

	sync pushbuttons[1:0] (.Clk(MAX10_CLK1_50), .d({~KEY[0], ~KEY[1]}), .q({syncd_reset_h, syncd_continue}));	
	
//=======================================================
//  Switch / Button Inputs
//=======================================================

	

	//assign signs = 2'b00;
	//assign hex_num_4 = 4'h4;
	//assign hex_num_3 = 4'h3;
	//assign hex_num_1 = 4'h1;
	//assign hex_num_0 = 4'h0;
	

	
//=======================================================
//  Clock Generation
//=======================================================
	
	// Main System Cloks
	logic MCLK; // 50 MHz
	logic VGA_CLK; // 25.175
	
	logic CPU_CLK;
	logic PPU_CLK;
	logic CPU_CLK_GATE;

	
	logic idiot_clk;
	// 50 MHz input, 
	// c0 is 25.175 for VGA timing.
	// C1 is 21.5 MHz, this is the master NES clock, all other NES clocks relative to this.
	
	main_clkgen mainclk_inst(.inclk0(MAX10_CLK1_50), .c0(idiot_clk), .c1(MCLK));
	
	// NES MCLK (21.5MHz) input, 
	// c0 is divided by 12
	// C1 is divided by 4
	// TODO: Replace CPU_CLK_GATE with CPU_CLK when single-step is removed
	nes_clkgen nesclk_inst(.inclk0(MCLK), .c0(CPU_CLK_GATE), .c1(PPU_CLK), .c2(VGA_CLK));
	
	
//=======================================================
//  NES Architecture Instantiation
//=======================================================

	T65_Dbg cpu_debug;
	
	logic [15:0]    ADDR_debug;
	logic 		 	 CPU_RW_n_debug;

	// Rom Programmer Interface
	logic [15:0] rom_prgmr_addr;
	logic [7:0]  rom_prgmr_data; 
	logic chr_rom_prgmr_wren, prg_rom_prgmr_wren; 
	
	// Switch Between Manual Clock and Normal Clock
	
	
	NES_ARCHITECUTRE NES(.MCLK(MCLK), .CPU_CLK(CPU_CLK), .PPU_CLK(PPU_CLK), .VGA_CLK(VGA_CLK), .CPU_RESET(syncd_reset_h), .cpu_debug(cpu_debug), .ADDR_debug(ADDR_debug), 
						 .CPU_RW_n_debug(CPU_RW_n_debug), .rom_prgmr_addr(rom_prgmr_addr), .rom_prgmr_data(rom_prgmr_data),
						 .chr_rom_prgmr_wren(chr_rom_prgmr_wren), .prg_rom_prgmr_wren(prg_rom_prgmr_wren), .*);
	
	
	/**
	assign hex_num_3 = ADDR_debug[15:12];
	assign hex_num_2 = ADDR_debug[11:8];
	assign hex_num_1 = ADDR_debug[7:4];
	assign hex_num_0 = ADDR_debug[3:0];
	*/
	
//=======================================================
//  Debug Display and Tooling
//=======================================================
	
	// Debug Switch Setup
	// SW[0] - High is manual CPU_CLK   (KEY[0]), low is PLL generated Clock
	// SW[1] - High is manual ROM clock (KEY[0]
	// SW[9:7] - Select what is displayed on the HEX
	//
	//
	//
	logic CPU_ENABLE;
	assign CPU_ENABLE = 1'b1;
	
	always_comb begin
		if (SW[0])
			CPU_CLK = syncd_continue;
		else
			CPU_CLK = CPU_CLK_GATE;
	end
		
	
	// Choose what to display on the HEX
	always_ff @ (posedge MAX10_CLK1_50) begin
		case (SW[9:7])
			// Display ROM Programmer Contents
			3'b000: begin // I don't think we need this one so who cares if it works yet, should ideally save these on rom_prgmr_wren posedge
				hex_num_5 <= rom_prgmr_addr[15:12];
				hex_num_4 <= rom_prgmr_addr[11:8];
				hex_num_3 <= rom_prgmr_addr[7:4];
				hex_num_2 <= rom_prgmr_addr[3:0];
				hex_num_1 <= rom_prgmr_data[7:4];
				hex_num_0 <= rom_prgmr_data[3:0];
			end
			// CPU Regs X, Y, A
			3'b001: begin
				hex_num_5 <= cpu_debug.X[7:4];
				hex_num_4 <= cpu_debug.X[3:0];
				hex_num_3 <= cpu_debug.Y[7:4];
				hex_num_2 <= cpu_debug.Y[3:0];
				hex_num_1 <= cpu_debug.A[7:4];
				hex_num_0 <= cpu_debug.A[3:0];
			end
			// CPU Regs PC, PF
			3'b011: begin
				hex_num_5 <= cpu_debug.PC[15:12];
				hex_num_4 <= cpu_debug.PC[11:8];
				hex_num_3 <= cpu_debug.PC[7:4];
				hex_num_2 <= cpu_debug.PC[3:0];
				hex_num_1 <= cpu_debug.PF[7:4];
				hex_num_0 <= cpu_debug.PF[3:0];
			end
			// CPU Regs SP
			3'b111: begin
				hex_num_5 <= cpu_debug.SP[15:12];
				hex_num_4 <= cpu_debug.SP[11:8];
				hex_num_3 <= cpu_debug.SP[7:4];
				hex_num_2 <= cpu_debug.SP[3:0];
				hex_num_1 <= cpu_debug.PF[7:4];
				hex_num_0 <= cpu_debug.PF[3:0];
			end
			
			// ADdress 
			3'b010: begin
				hex_num_5 <= ADDR_debug[15:12];
				hex_num_4 <= ADDR_debug[11:8];
				hex_num_3 <= ADDR_debug[7:4];
				hex_num_2 <= ADDR_debug[3:0];
				hex_num_1 <= 1'h1;
				hex_num_0 <= 1'h1;
			end
			
			default: begin
				hex_num_5 <= 1'h1;
				hex_num_4 <= 1'h1;
				hex_num_3 <= 1'h1;
				hex_num_2 <= 1'h1;
				hex_num_1 <= 1'h1;
				hex_num_0 <= 1'h1;
			end
			
		endcase
	end
	// Might need to latch these
	
	
	
	assign LEDR[7] = chr_rom_prgmr_wren | prg_rom_prgmr_wren;
	
	
//=======================================================
//  Toplevel SGTL5000 Audio Routing
//=======================================================

	logic I2C_SDA, I2C_SCL;
	
	// Arduino Ports
	assign I2C_SDA = ARDUINO_IO[14];
	assign I2C_SCL = ARDUINO_IO[15];
	
	// Audio I2C Slave
	/**
	logic	s_sda_in;
	logic	s_scl_in;
	logic	s_sda_oe;
	logic	s_scl_oe;
	
	assign s_sda_in = I2C_SDA;
	assign I2C_SDA = (s_sda_oe)?  1'b0 : 1'bz;
	
	assign s_scl_in = I2C_SCL;
	assign I2C_SCL = (s_scl_oe)?  1'b0 : 1'bz;
	
	logic [1:0] SGTL_CLK;
	
	// Divide clk by 4
	always_ff @ (posedge MAX10_CLK1_50) begin
		SGTL_CLK <= SGTL_CLK + 1;
	end
	
	
	assign ARDUINO_IO[3] = SGTL_CLK[1]; // 12.5 MHz SGTL Clock
	
	logic sample_gen_dout;
	
	
	// 44.1kHz Sampling Rate
	
	sgtl_audio_interface I2S(.MCLK(ARDUINO_IO[3]), .LRCLK(ARDUINO_IO[4]), .SCLK(ARDUINO_IO[5]), .target_freq(SW[9:2]), .wave_select(SW[1:0]), .reset(Reset_h), .DOUT(sample_gen_dout));
	
	assign ARDUINO_IO[1] = 1'bz; // Input to FPGA
	assign sample_gen_dout = 1'bz;
	
	logic SGTL_SERIAL_DIN;
	
	always_comb begin
		if (play_mode)
			SGTL_SERIAL_DIN = ARDUINO_IO[1];
		else
			SGTL_SERIAL_DIN = sample_gen_dout;
	end
	
	assign ARDUINO_IO[2] = SGTL_SERIAL_DIN; // Output from FPGA
	*/
	
	
//=======================================================
//  Toplevel Video Instantiation (Moved to inside PPU)
//=======================================================
	
	/**
	logic VGA_Clk;
	logic blank_n;
	
	assign VGA_CLK = MAX10_CLK1_50;
	// This depends on our resolution
	logic [10:0] drawx, drawy;
	
	vga_controller vga_ctrl (.Clk(VGA_CLK), .Reset(1'b0), .hs(VGA_HS), .vs(VGA_VS), .blank(blank_n), .DrawX(drawx), .DrawY(drawy));
	 
	always_ff @ (posedge VGA_CLK) begin 
		if (blank_n) begin 
			VGA_R <= 4'b1111;
			VGA_G <= 4'b0000;
			VGA_B <= 4'b1111;
		end
		
		else if (~blank_n) begin // Blanking interval
			VGA_R <= 4'b0000;
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end
	end
	*/
	
//=======================================================
//  SOC Instantiation
//=======================================================
	
	//remember to rename the SOC as necessary
	toplevel_soc u0 (
		.clk_clk                           (MAX10_CLK1_50),    //clk.clk
		.reset_reset_n                     (1'b1),             //reset.reset_n
		.altpll_0_locked_conduit_export    (),    			   //altpll_0_locked_conduit.export
		.altpll_0_phasedone_conduit_export (), 				   //altpll_0_phasedone_conduit.export
		.altpll_0_areset_conduit_export    (),     			   //altpll_0_areset_conduit.export
    
		.key_external_connection_export    (KEY),    		   //key_external_connection.export
		
		//I2C
		.i2c_0_i2c_serial_sda_in(s_sda_in),        //        i2c_0_i2c_serial.sda_in
		.i2c_0_i2c_serial_scl_in(s_scl_in),        //                        .scl_in
		.i2c_0_i2c_serial_sda_oe(s_sda_oe),        //                        .sda_oe
		.i2c_0_i2c_serial_scl_oe(s_scl_oe),
		
		//SDRAM
		.sdram_clk_clk(DRAM_CLK),            				   //clk_sdram.clk
	   .sdram_wire_addr(DRAM_ADDR),               			   //sdram_wire.addr
		.sdram_wire_ba(DRAM_BA),                			   //.ba
		.sdram_wire_cas_n(DRAM_CAS_N),              		   //.cas_n
		.sdram_wire_cke(DRAM_CKE),                 			   //.cke
		.sdram_wire_cs_n(DRAM_CS_N),                		   //.cs_n
		.sdram_wire_dq(DRAM_DQ),                  			   //.dq
		.sdram_wire_dqm({DRAM_UDQM,DRAM_LDQM}),                //.dqm
		.sdram_wire_ras_n(DRAM_RAS_N),              		   //.ras_n
		.sdram_wire_we_n(DRAM_WE_N),                		   //.we_n

		//USB SPI	
		.spi0_SS_n(SPI0_CS_N),
		.spi0_MOSI(SPI0_MOSI),
		.spi0_MISO(SPI0_MISO),
		.spi0_SCLK(SPI0_SCLK),
		
		//USB GPIO
		.usb_rst_export(USB_RST),
		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		
		// Game Rom Programmer
	
		.game_rom_conduit_rom_data(rom_prgmr_data),   //        game_rom_conduit.to_game_rom
		.game_rom_conduit_prg_rom_write(prg_rom_prgmr_wren),     	//                        .write_rom
		.game_rom_conduit_rom_addr(rom_prgmr_addr), 
		.game_rom_conduit_chr_rom_write(chr_rom_prgmr_wren),     	//                        .rom_addr
		
		//LEDs and HEX
		//.hex_digits_export({hex_num_4, hex_num_3, hex_num_1, hex_num_0}),
		//.leds_export({hundreds, signs, LEDR}),
		.keycode_export(keycode)
		
		
	 );

endmodule
