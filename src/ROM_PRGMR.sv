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
	output [7:0] 	ROM_DATA,
	output logic	CHR_ROM_WRITE,
	output logic	PRG_ROM_WRITE
	
);


// Use top 8 bits for mapper logic etc.

always_ff @ (posedge CLK) begin
	if (AVL_WRITEDATA[31])
		PRG_ROM_WRITE <= AVL_WRITE;
	else
		CHR_ROM_WRITE <= AVL_WRITE;
end

assign ROM_ADDR = AVL_WRITEDATA[15:0];
assign ROM_DATA = AVL_WRITEDATA[23:16];

endmodule