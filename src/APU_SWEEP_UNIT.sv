//=======================================================
//  APU_SWEEP_TIMER_UNIT
//  - Sweeps a pringle for the pulsesr
//  - This is the same as the timer
//  
//=======================================================

module APU_SWEEP_TIMER_UNIT(
	input clk, // APU_clk
	input reset,
	
	input timer_load,
	input [10:0] timer_data_in,
	
	output sequencer_clock
);

logic [10:0] timer;
logic [10:0] counter;

always_ff @ (posedge clk or posedge reset) begin
	if (reset) begin
		pulse_sequencer_counter[0] <= 11'b0;
	end
	else begin
		if (counter == timer) begin
			counter <= 0;
		end
		else
			counter <= counter + 1;
	end
end

always_comb begin
	sequencer_clock = 1'b0;
	
	if (counter == timer)
		sequencer_clock = 1'b1;

end

endmodule