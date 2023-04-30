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
	
	input mirroring,
	
	input wren, rden,
	
	output logic [7:0] data_out
);

// Size is 2^11
//TODO: [11:10] should be 0 for no mirroring


logic [10:0] addr_mirrored;

assign addr_mirrored = {mirroring, addr[9:0]};



// TODO: Minimize this

logic [7:0] mem [2048]; // Whole PPU address space for now

always_ff @ (posedge clk) begin
	if (wren)
		mem[addr_mirrored] <= data_in;
	if (rden)
		data_out <= mem[addr_mirrored];
	
end

endmodule