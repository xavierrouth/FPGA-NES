//=======================================================
//  Module Includes / Typedefs For Now
//=======================================================

typedef struct packed {
	logic [7:0] I;
	logic [7:0] A;
	logic [7:0] X;
	logic [7:0] Y;
	logic [7:0] S;
	logic [7:0] P;
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
	input				MCLK,
	input				CPU_CLK,
	input				CPU_RESET,

	// ROM Programmer
	input 				rom_prgmr_wren, rom_prgmr_rden,
	input [15:0]		rom_prgmr_addr,
	input [7:0]			rom_prgmr_data_in,
	output [7:0]			rom_prgmr_data_out,

	// Video 
	
	// Debug Signals
	output T65_Dbg  	cpu_debug,
	output [15:0]    	ADDR_debug,
	output 			 	CPU_RW_n_debug
);


//=======================================================
//  Bus Signals
//=======================================================

logic [15:0] ADDR_BUS;
logic [7:0]  DATA_BUS;

// CPU Signals
logic [15:0] CPU_ADDR;
logic [7:0]  CPU_DATA_OUT;
logic 		 CPU_RW_n; // Read is high, write is low
logic		 CPU_ENABLE;

// SYSRAM Signals
logic [7:0] SYSRAM_DATA_OUT;
logic SYSRAM_wren, SYSRAM_rden; 

// Cartridge / ROM Signals
logic [7:0] CARTRIDGE_DATA_OUT;
logic CARTRIDGE_rden;


assign CPU_ENABLE = 1'b1;
assign ADDR_BUS = CPU_ADDR;

//=======================================================
//  Bus Architecture / Memory Mapped Logic
//=======================================================

assign ADDR_BUS = CPU_ADDR; // I think this is always the case

always_comb begin : BUS_SELECTION
	// Default Values
	SYSRAM_wren = 1'b0;
	SYSRAM_rden = 1'b0;
	DATA_BUS = 8'hFF;
	CARTRIDGE_rden = 1'b0;

	// ------ Priority Mux Bus Control ---------

	// System Ram [$0000 - $0FFF]
	if (ADDR_BUS <= 16'h0FFF) begin
		DATA_BUS = SYSRAM_DATA_OUT;
		SYSRAM_wren = CPU_RW_n;
		SYSRAM_rden = ~CPU_RW_n;
	end
	// Cartridge / ROM [$4020 - $FFFF]
	else if (ADDR_BUS >= 16'h4020) begin
		// TODO: Enable other things than just the CPU (like PPU) to read from here.
		DATA_BUS = CARTRIDGE_DATA_OUT;
		CARTRIDGE_rden = CPU_RW_n;
	end
end
//=======================================================
//  Debug Signals
//=======================================================

assign ADDR_debug = CPU_ADDR;
assign CPU_RW_n_debug = CPU_RW_n; 

//=======================================================
//  Memory Instantiation
//=======================================================

// System Ram
logic RAM_CLK;
logic sysram_enable;

assign RAM_CLK = CPU_CLK;
assign sysram_enable = 1'b1;


//=======================================================
//  Module Instatiation
//=======================================================

CPU_2A03 cpu_inst(.CLK(CPU_CLK), .ENABLE(CPU_ENABLE), .RESET_n(CPU_RESET), .DATA_IN(DATA_BUS), .ADDR(CPU_ADDR), 
				  .DATA_OUT(CPU_DATA_OUT), .RW_n(CPU_RW_n), .cpu_debug(cpu_debug));
				  
SYS_RAM sysram_inst(.clk(RAM_CLK), .data_in(DATA_BUS), .addr(ADDR_BUS[10:0]), .wren(SYSRAM_wren), .rden(SYSRAM_rden), .data_out(SYSRAM_DATA_OUT));

CARTRIDGE cart_inst(.clk(CPU_CLK), .prgmr_data_in(rom_prgmr_data), .nes_addr(ADDR_BUS[15:0]), .prgmr_addr(rom_prgmr_addr), 
					.nes_rden(CARTRIDGE_rden), .prgmr_wren(rom_prgmr_active), .nes_data_out(CARTRIDGE_DATA_OUT));

endmodule