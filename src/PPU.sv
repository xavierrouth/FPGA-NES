//=======================================================
//  PPU
//  - This module represents the PPU (Picture Procesing Unit) of the NES architecture.
//    It is connected to its own personal BUS, and also must be connected to a VGA adapter 
//    at some point in the architecture.
//
//  - CPU BUS Section [$2000 - $3FFF] ~ Alot
//  - NOTE: This is mirrored every 8 bytes, meaning we only have a 3 bit address into
//    the control registers
//
//  - TODO:
//		Adapt for VGA
//
//=======================================================

module PPU (
	input clk,
	//input enable,
	
	// CPU BUS interface
	input [7:0] CPU_DATA_IN,
	input [2:0] CPU_ADDR,
	
	input CPU_wren, CPU_rden, // CPU wants to read / CPU wants to write
	
	output logic [7:0] CPU_DATA_OUT,
	
	//PPU BUS interface
	input [7:0] PPU_DATA_IN,
	
	output [7:0] PPU_DATA_OUT,
	output [13:0] PPU_ADDR,
	output PPU_WRITE, PPU_READ
);

logic [7:0] PPUCTRL, PPUMASK, PPUSTATUS, OAMADDR, OAMDATA, PPUSCROLL, PPUADDR, PPUDATA;

endmodule