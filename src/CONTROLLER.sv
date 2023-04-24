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
	
	input clk,
	input rden, wren,
	input reset,
	
	input [7:0] data_in,
	
	input [7:0] keycodes_in, // Keycodes from NES
	
	
	output logic [7:0] data_out // Only lowest bit of this is ever used
);

logic [7:0] keycodes; 

assign data_out[7:1] = 7'b0;

logic strobe;

logic shift_req;
logic shift_handle;

// TODO: Add second controller

//We Have to do the clk flags thing to handle this async stuff, I think its the best way at this point

// Positive edge detector
logic rden_prev;



always_ff @ (posedge clk) begin
	if (~reset) begin
		// Wait to detect a posedge
		if (~rden_prev)
			rden_prev <= rden;
		else if (~rden) 
			rden_prev <= 1'b0; // nwsdawdwdasdegedge detected, so reset
		else 
			rden_prev <= rden_prev; // No change, so keep trucking
			
		// posedge signal a "shift request"
		// Edge and that edge is positive
		if (rden_prev != rden & rden == 1'b1) begin
			shift_req <= ~shift_req;
			data_out[0] <= keycodes[0];
		end
		
		// Hnadle Stuff
		if (wren)
			strobe <= data_in[0];
		// Do we shift on wren?
		
		// Handle Shifts
		
		// What happens if we get a shift request when strobing?, we want to ignore it, not buffer it until strobing is done
		// ALWAYS handle the shift request
		if (shift_req ^ shift_handle) begin
			shift_handle <= ~shift_handle;
			
			if (~strobe) 
				keycodes <= {1'b1, keycodes[7:1]};
			else // Strobe
				keycodes <= keycodes_in;
		end
		
		if (strobe)
			keycodes <= keycodes_in;
		
		
			
	end else begin // Reset
		rden_prev <= 1'b0;
		shift_req <= 1'b0;
		keycodes <= 8'b0;
		strobe <= 1'b0;
		shift_handle <= 1'b0;
		data_out[0] <= 1'b0;
	end
	
end
	
endmodule