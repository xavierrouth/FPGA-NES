//=======================================================
//  APU_ENVELOPE_GENERATOR
//  - Generators an envelope
//  
//=======================================================

module APU_ENVELOPE_GENERATOR(
	input cpu_clk,
	input clk_edge, // Quarter Clock
	
	input reset,
	input loop,
	input start,
	
	input constant_volume,
	
	input [3:0] volume, 
	
	output [3:0] envelope_out
);


logic clk_handle;	

logic [3:0] divider_counter;
logic [3:0] divider_period;
assign divider_period = volume;
logic [3:0] decay_level;

always_ff @ (posedge cpu_clk) begin
	if (reset) begin
		decay_level <= 4'b0;
		divider_counter <= 4'b0;
	end
	else begin
		// Quarter Clock
		if (clk_edge ^ clk_handle) begin
			clk_handle <= ~clk_handle;
			if	(start == 0) begin
				// Clock Divider
				if (divider_counter == 0) begin
					divider_counter <= divider_period;
					// Clock Decay Thingy
					if (loop)
						decay_level <= 4'd15;
					else	
						decay_level <= decay_level - 1;
				end
				else
					divider_counter <= divider_counter - 1;
			end
			else begin
				divider_counter <= divider_period;
				decay_level <= 4'd15;
			end
			
		end
	end
end

always_comb begin
	if (constant_volume)
		envelope_out = volume;
	else 
		envelope_out = decay_level;
end

endmodule

