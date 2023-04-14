//=======================================================
//  ROM PRGMR
//  - This module is what the NIOS II interfaces with via the Avalon MM BUS in order to program the game ROMs.
//    It should be instantiated as an element on the AVL MM BUs like we did in lab 7.2
// 
//  
//  - TODO:
//		Make this work
//  
//=======================================================

module ROM_PRGMR(
	// Avalon MM Side
	input 			CLK,
	input 			RESET,
	input  [1:0] 	AVL_ADDR,
	input   			AVL_CS,
	input 			AVL_WRITE,
	input  [31:0] 	AVL_WRITEDATA, //Ignore top 8 bits
	
	// NES Side
	output [15:0] 	ROM_ADDR,
	output [7:0] 	TO_ROM,
	output 			WRITE_ROM
	
);

// Probably don't have to wait here just say fuck it

always_comb begin
	if (AVL_WRITE) begin
		ROM_ADDR = AVL_WRITEDATA[15:0];
		TO_ROM = AVL_WRITEDATA[23:16];
		WRITE_ROM = AVL_WRITE; // Writing to this module at any address is like writing to ROM
	end else begin
		ROM_ADDR = 16'b0;
		TO_ROM = 8'b0;
		WRITE_ROM = 1'b0;
	end
end


endmodule