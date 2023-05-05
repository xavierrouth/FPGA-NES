//=======================================================
//  APU_PULSE_SEQUENCER
//  - Sweeps a pringle for the pulsesr
//  - This is the same as the timer
//  
//=======================================================

module APU_PULSE_SEQUENCER(
	input cpu_clk,
	input clk_edge, // Sequencer Clock 
	
	input reset,
	input [1:0] duty, //Ignore Duty for now
	
	output waveform
);

logic [7:0] pulse_wave = {1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1};
logic [2:0] idx;

logic clk_handle;

always_ff @ (posedge cpu_clk) begin
	if (reset) begin
		idx <= 1'b0;
	end
	else if (clk_handle ^ clk_edge) begin
		clk_handle <= ~clk_handle;
		idx <= idx + 1;
	end
end


assign waveform = pulse_wave[idx];

endmodule