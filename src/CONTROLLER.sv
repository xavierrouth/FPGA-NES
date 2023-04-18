//=======================================================
//  CONTROLLER
//  - This module represents the controller that is connected to the NES's memory mapped bus.
//
//	 - BUS Section [$4016 / 4017]
//
//		CPU side:
//
//	   The procedure for reading input from the controller is as follows:
//    1) Write 1 to $4016 to signal controller to poll input
//    2) Write 0 to $4016 to finish the poll
//    3) Read polled data one bit at a time from $4016 or $4017
//
//	   Controller Hardware side:
//
//    The low bit of the controller register controls an 8 bit shift register.
// 	Reading a 1 causes a parllel load from the keycodes (poll input state)
//    Reading a 0 causes the beginning of serial output.
//    When the ctrl register is 0, we pulse the clk of the controller by reading from $4016 or $4017, 
//    depending on the controller we want.
//		This read will provide us one bit from the controller's keycode register, and shift the bits down
//    in preparation for the next bit. 
//
//
//		Specifically, CLK = (R/W nand (ADDRESS == $4016/$4017)) (i.e., CLK is low only when reading $4016/$4017, since R/W high means read)
//
//  - TODO: Hook up the parallel load to the NIOS II to read keycodes.
// 			We probably want the nios II to write to some register every n cycles that updates
//				us about our keycodes.
//				Make sure to exibit correct open bus / unconected data line behavior.
//  	
//
//=======================================================

module CONTROLLER (
	
	input rden, wren,
	
	input [7:0] data_in,
	
	input [7:0] keycodes_in, // Keycodes from NES
	
	
	output [7:0] data_out // Only lowest bit of this is ever used
);

assign data_out[7:1] = 7'b0;

logic [7:0] keycodes;


// This is all wrong, we should adapt the clock outside of this
always_ff @ (posedge rden or posedge wren) begin
	if (wren) begin
		if (data_in[0]) // Parallel load
			keycodes <= keycodes_in;
		else
			keycodes <= keycodes;
			
	end
end


endmodule