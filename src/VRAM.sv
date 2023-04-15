//=======================================================
//  VRAM
//  - This module represents the video ram that is available to the PPU,
//		This consists of two main components, nametables and palettes.
// 
//  - Nametable PPU BUS Section [$2000 - $27FF] NOTE: Weird Mirroring
//
//
//	 - Palette PPU BUS Section [$3F00 - $3F1F] NOTE: Weird Mirroring
//
//
//  - TODO:
//		Mirroring and Mappers, Maybe split into two sections eventually
// 	look into PPUDATA read buffer
//
//  
//=======================================================

module VRAM(
	input clk,
	//input enable,
	
	input [7:0] data_in,
	input [13:0] addr,
	
	input wren, rden,
	
	output logic [7:0] data_out
);

// Size is 2^11

// TODO: Minimize this
logic [7:0] mem [16384]; // Whole PPU address space for now

always_ff @ (posedge clk) begin
	if (wren)
		mem[addr] <= data_in;
	if (rden)
		data_out <= mem[addr];
	
end

endmodule