//=======================================================
//  APU_LENGTH_COUNTER
//  - This module represents the length counter component used in the various APU channels.
//  - It is clocked at the half clock rate produced by the frame counter / sequencer.
// 
//  
//=======================================================


module APU_LENGTH_COUNTER(
	input cpu_clk, // cpu_clk
	input clk_edge, // Half_clock
	
	input load,
	input reset,
	
	input halt,
	input enable,
	
	input [4:0] data_in,
	
	output logic [7:0] counter_out
);
/**
logic [7:0] lc_lookup_table [32] = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd11, 8'd12, 8'd13, 8'd14, 
8'd15, 8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 8'd22, 8'd23, 8'd24, 8'd25, 8'd26, 8'd27, 8'd28, 8'd29, 8'd30, 8'd31, 8'd32}; 
*/
/**
logic [7:0] lc_lookup_table [32] = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 
8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd32, 8'd30}; 
*/

logic [7:0] lc_lookup_table [32] = '{8'd10, 8'd254, 8'd20, 8'd2, 8'd40, 8'd4, 8'd80, 8'd6, 8'd160, 8'd8, 8'd60, 8'd10, 8'd14, 8'd12, 
8'd26, 8'd14, 8'd12, 8'd16, 8'd24, 8'd18, 8'd48, 8'd20, 8'd96, 8'd22, 8'd192, 8'd24, 8'd72, 8'd26, 8'd16, 8'd28, 8'd32, 8'd30}; 


/**'{8'd10, 8'd254, 8'd20, 8'd2, 8'd40, 8'd4, 8'd80, 8'd6, 8'd160, 8'd8, 8'd60, 8'd10, 8'd14, 8'd12, 
8'd26, 8'd14, 8'd12, 8'd16, 8'd24, 8'd18, 8'd48, 8'd20, 8'd96, 8'd22, 8'd192, 8'd24, 8'd72, 8'd26, 8'd16, 8'd28, 8'd32, 8'd30}; 
*/
logic [7:0] counter;
assign counter_out = counter;

logic prev_enable;

logic clk_handle;

always_ff @ (posedge cpu_clk) begin
	if (enable) begin
		if (load) begin
			counter <= lc_lookup_table[data_in];
		end
		else if (clk_edge ^ clk_handle) begin
			clk_handle <= ~clk_handle;
			if (halt | counter == 0) begin
				counter <= counter;
			end
			// Docount down
			else
				counter <= counter - 1;
		end
	end

	else
		counter <= 0;
	
end

endmodule