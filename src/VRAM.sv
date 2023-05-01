//=======================================================
//  VRAM
//  - This module represents the video ram that is available to the PPU,
//		This consists of nametables
// 
//  - Nametable PPU BUS Section [$2000 - $27FF] NOTE: Weird Mirroring
//	
//
//  
//=======================================================

module VRAM(
	input clk,
	//input enable,
	
	input [7:0] data_in,
	input [11:0] addr,
	
	input mirroring,
	
	input wren, rden,
	
	output logic [7:0] data_out
);

// Size is 2^11 to address 20KiB
//TODO: [11:10] should be 0 for no mirroring


// If we are doing vertical mirroring, we want to ignore bit 11.
// If we are doing horizontal mirroring, we want to ignore bit 10.

logic [10:0] addr_mirrored;

always_comb begin
	if (mirroring == 1'b1) // Lets say this is vertical mirroring
		addr_mirrored = {addr[10:0]}; // Ignore bit 11
	else 
		addr_mirrored = {addr[11], addr[9:0]}; // Ignore bit 10
end




// TODO: Minimize this

logic [7:0] mem [2048]; // Whole PPU address space for now

always_ff @ (posedge clk) begin
	if (wren)
		mem[addr_mirrored] <= data_in;
	if (rden)
		data_out <= mem[addr_mirrored];
	
end

endmodule