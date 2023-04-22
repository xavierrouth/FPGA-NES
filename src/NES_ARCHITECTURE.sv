//=======================================================
//  Module Includes / Typedefs For Now
//=======================================================

typedef struct packed {
	logic [15:0] PC; // PC, not sure which it is unclear
	logic [15:0] SP; // Stack Pointer
	logic [7:0] PF; // Processor Flags
	logic [7:0] X;
	logic [7:0] Y; 
	logic [7:0] A; 
} T65_Dbg;


//=======================================================
//  NES_ARCHITECTURE
//  - This module represents the top-level wrapper for our NES system architecture,
//    the goal is to be as hardware accurate to the original NES for all logic here.
//
//  - TODO:
//		Everything
//
//=======================================================

module NES_ARCHITECUTRE (
	// Clocks
	input					MCLK,
	input					CPU_CLK,
	input					PPU_CLK,
	
	input 				VGA_CLK,
	
	input 				CPU_ENABLE,
	input					CPU_RESET,
	
	

	// ROM Programmer
	input 				prg_rom_prgmr_wren, chr_rom_prgmr_wren,
	input [15:0]		rom_prgmr_addr,
	input [7:0]			rom_prgmr_data,
	input [7:0] 		controller_keycode,

	// Video 
	output             VGA_HS,
	output             VGA_VS,
	output   [ 3: 0]   VGA_R,
	output   [ 3: 0]   VGA_G,
	output   [ 3: 0]   VGA_B,
	
	// Debug Signals
	input [4:0] 		DEBUG_SWITCHES,
	
	output T65_Dbg  	cpu_debug,
	output [15:0]    	ADDR_debug,
	output 			 	CPU_RW_n_debug
);


//=======================================================
//  CPU Bus Signals
//=======================================================

logic [15:0] CPU_ADDR_BUS;
logic [7:0]  CPU_DATA_BUS;

// CPU Signals
logic [15:0] CPU_ADDR;
logic [7:0]  CPU_DATA_OUT;
logic 		 CPU_RW_n; // Read is high, write is low

//Controller Signals

logic CONTROLLER_wren, CONTROLLER_rden;
logic [7:0] CONTROLLER_DATA_OUT;

// PPU-CPU Signals
logic [7:0] PPU_CPU_DATA_OUT;
logic CPU_PPU_wren, CPU_PPU_rden;

// SYSRAM Signals
logic [7:0] SYSRAM_DATA_OUT;
logic SYSRAM_wren, SYSRAM_rden; 

// PRG-ROM Signals
logic [7:0] PRG_ROM_DATA_OUT;
logic PRG_ROM_rden;


//=======================================================
//  CPU Bus Architecture / Memory Mapped Logic
//=======================================================

assign CPU_ADDR_BUS = CPU_ADDR; // I think this is always the case

always_comb begin : CPU_BUS_SELECTION
	// Default Values
	SYSRAM_wren = 1'b0;
	SYSRAM_rden = 1'b0;
	
	CPU_PPU_wren = 1'b0;
	CPU_PPU_rden = 1'b0;
	
	CPU_DATA_BUS = 8'hAA;
	PRG_ROM_rden = 1'b0;
	
	CONTROLLER_rden = 1'b0;
	CONTROLLER_wren = 1'b0;
	
	// ------ CPU Write ---------
	if (~CPU_RW_n) begin
		CPU_DATA_BUS = CPU_DATA_OUT;
		
		// System Ram [$0000 - $0FFF]
		if (CPU_ADDR_BUS <= 16'h0FFF)
			SYSRAM_wren = 1'b1;
		
		// CONTROLLER [$4016]
		if (CPU_ADDR_BUS == 16'h4016) begin
			CONTROLLER_wren = 1'b1;
		end
		
		// PPU Control Registers [$2000 - $3FFF] (Repeats every 8 bytes)
		if ((CPU_ADDR_BUS >= 16'h2000) & (CPU_ADDR_BUS <= 16'h3FFF)) begin
			CPU_PPU_wren = 1'b1;
		end
	end
	
	// ------ CPU Read  ---------
	else if (CPU_RW_n) begin
	
		// System Ram [$0000 - $0FFF]
		if (CPU_ADDR_BUS <= 16'h0FFF) begin
			CPU_DATA_BUS = SYSRAM_DATA_OUT;
			SYSRAM_rden = 1'b1;
		end
		// CONTROLLER [$4016 - $4017]
		if (CPU_ADDR_BUS == 16'h4016 | CPU_ADDR_BUS == 16'h4017) begin
			CONTROLLER_rden = 1'b1;
			CPU_DATA_BUS = CONTROLLER_DATA_OUT;
		end
		// PRG-ROM [$4020 - $FFFF]
		else if (CPU_ADDR_BUS >= 16'h4020) begin
			CPU_DATA_BUS = PRG_ROM_DATA_OUT;
			PRG_ROM_rden = 1'b1;
		end
		
		// PPU Control Registers [$2000 - $3FFF] (Repeats every 8 bytes)
		if (CPU_ADDR_BUS >= 16'h2000 && CPU_ADDR_BUS <= 16'h3FFF) begin
			// Do Reads / Writes matter here?
			CPU_DATA_BUS = PPU_CPU_DATA_OUT;
			CPU_PPU_rden = 1'b1;
		end
	end
end

//=======================================================
//  PPU Bus Signals
//=======================================================

logic [13:0] PPU_ADDR_BUS;
logic [7:0]  PPU_DATA_BUS;

// PPU Signals
logic [13:0] PPU_ADDR;
logic [7:0]  PPU_DATA_OUT;

logic PPU_READ, PPU_WRITE; // Let's split this into two signals, unlike CPU

// CHR-ROM Signals
logic [7:0] CHR_ROM_DATA_OUT;
logic CHR_ROM_rden;

// VRAM Signals
logic [7:0] VRAM_DATA_OUT;
logic VRAM_rden, VRAM_wren;

//=======================================================
//  PPU Bus Architecture / Memory Mapped Logic
//=======================================================

assign PPU_ADDR_BUS = PPU_ADDR; // I think this is always the case

always_comb begin : PPU_BUS_SELECTION
	// Default Values
	PPU_DATA_BUS = 8'hAA;
	VRAM_rden = 1'b0;
	VRAM_wren = 1'b0;
	CHR_ROM_rden = 1'b0;

	// ------ Priority Mux Bus Control ---------

	// CHR-ROM / Pattern Tables [$0000 - $1FFF]
	
	
	// VRAM / Name Tables [$2000 - $27FF] // Weir dMirroring stuff who cares rn
	
	// Palette RAM [$3F00 - $3FFF] // Weir dMirroring stuff who cares rn
	
	
	// ------ PPU Write --------- 
	if (PPU_WRITE) begin
		PPU_DATA_BUS = PPU_DATA_OUT;
		
		// VRAM / Name Tables [$2000 - $3FFF]
		if (PPU_ADDR_BUS >= 14'h2000)
			VRAM_wren = 1'b1;
	end
	 
	// ------ PPU Read  ---------
	else if (PPU_READ) begin
	
		// CHR-ROM / Pattern Tables [$0000 - $1FFF]
		if (PPU_ADDR_BUS <= 14'h1FFF) begin
			PPU_DATA_BUS = CHR_ROM_DATA_OUT;
			CHR_ROM_rden = 1'b1;
		end
		
		// TODO: Name Tables from Palette?
		// VRAM / Name Tables / Palette [$2000 - $3FFF]
		else if (PPU_ADDR_BUS >= 14'h2000) begin
			PPU_DATA_BUS = VRAM_DATA_OUT;
			VRAM_rden = 1'b1;
		end
	end
end


//=======================================================
//  Debug Signals
//=======================================================

assign ADDR_debug = CPU_ADDR;
assign CPU_RW_n_debug = CPU_RW_n; 

logic debug_enable_nmi;
assign debug_enable_nmi = DEBUG_SWITCHES[0];

//=======================================================
//  Memory Instantiation
//=======================================================


logic MEM_CLK;
assign MEM_CLK = MCLK;

// System Ram
logic sysram_enable;
assign sysram_enable = 1'b1;

logic RESET;

logic NMI_n;

//=======================================================
//  Module Instatiation
//=======================================================

CONTROLLER playerone(.rden(CONTROLLER_rden), .wren(CONTROLLER_wren), .data_in(CPU_DATA_BUS), .keycodes_in(controller_keycode), .data_out(CONTROLLER_DATA_OUT));

CPU_2A03 cpu_inst(.CLK(CPU_CLK), .ENABLE(CPU_ENABLE), .RESET(CPU_RESET), .DATA_IN(CPU_DATA_BUS), .ADDR(CPU_ADDR), 
				  .DATA_OUT(CPU_DATA_OUT), .RW_n(CPU_RW_n), .cpu_debug(cpu_debug), .NMI_n(NMI_n));

SYS_RAM sysram_inst(.clk(MEM_CLK), .data_in(CPU_DATA_BUS), .addr(CPU_ADDR_BUS[10:0]), .wren(SYSRAM_wren), .rden(SYSRAM_rden), .data_out(SYSRAM_DATA_OUT));

PRG_ROM prg_rom_inst(.clk(MEM_CLK), .prgmr_data(rom_prgmr_data), .nes_addr(CPU_ADDR_BUS[15:0]), .prgmr_addr(rom_prgmr_addr), 
					.nes_rden(PRG_ROM_rden), .prgmr_wren(prg_rom_prgmr_wren), .nes_data_out(PRG_ROM_DATA_OUT));
					
CHR_ROM chr_rom_inst(.clk(MEM_CLK), .prgmr_data(rom_prgmr_data), .nes_addr(PPU_ADDR_BUS[13:0]), .prgmr_addr(rom_prgmr_addr), 
					.nes_rden(CHR_ROM_rden), .prgmr_wren(chr_rom_prgmr_wren), .nes_data_out(CHR_ROM_DATA_OUT));
					
PPU ppu_inst(.CLK(PPU_CLK), .RESET(RESET), .VIDEO_CLK(VGA_CLK), .NMI_n(NMI_n), .CPU_DATA_IN(CPU_DATA_BUS), .CPU_ADDR(CPU_ADDR[2:0]), .CPU_DATA_OUT(PPU_CPU_DATA_OUT), .CPU_wren(CPU_PPU_wren), .CPU_rden(CPU_PPU_rden), 
				.PPU_DATA_IN(PPU_DATA_BUS), .PPU_DATA_OUT(PPU_DATA_OUT), .PPU_ADDR(PPU_ADDR), .PPU_READ(PPU_READ), .PPU_WRITE(PPU_WRITE), .*);
				
VRAM vram_inst(.clk(MEM_CLK), .data_in(PPU_DATA_BUS), .addr(PPU_ADDR_BUS), .wren(VRAM_wren), .rden(VRAM_rden), .data_out(VRAM_DATA_OUT));
			
endmodule