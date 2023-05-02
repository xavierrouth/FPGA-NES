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
	output logic	PRG_ROM_WRITE,
	
	output logic   mirroring_mode,
	output logic	is_chr_ram
	
);


// Use top 8 bits for mapper logic etc.

always_ff @ (posedge CLK) begin
	if (AVL_CS) begin
		if (AVL_WRITEDATA[31])
			PRG_ROM_WRITE <= AVL_WRITE;
		else
			CHR_ROM_WRITE <= AVL_WRITE;
			
		if (AVL_WRITEDATA[30]) 
			mirroring_mode <= AVL_WRITEDATA[29];
		if (AVL_WRITEDATA[28])
			is_chr_ram <= AVL_WRITEDATA[27];
	end
	else begin
		PRG_ROM_WRITE <= 1'b0;
		CHR_ROM_WRITE <= 1'b0;
	end
end

assign ROM_ADDR = AVL_WRITEDATA[15:0];
assign ROM_DATA = AVL_WRITEDATA[23:16];

endmodule