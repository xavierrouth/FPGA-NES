module sgtl_audio_interface(
	input 	MCLK,
	input 	LRCLK,
	input 	SCLK,
	
	input [7:0] target_freq,
	input [1:0] wave_select,
	
	input		reset,
	
	output 	DOUT // MCLK 
);

// For now just have this provide samples I guess at the correct frequency


logic [23:0] sample;
logic [31:0] long;

logic load_sample;
logic shift_sample;
logic generate_sample;

logic[10:0] sawtooth, square, triangle;
logic[10:0] counter; // Counts up to target Freq

assign DOUT = long[31];

// Counter
always_ff @(posedge LRCLK) begin
	if (reset)
		counter <= 0;
	else begin
		if (counter > (target_freq))
			counter <= 0;
		else
			counter <= counter + 1;
	end
end

// Sawtooth
assign sawtooth = counter - (target_freq >> 1);

// Square Wave
always_comb begin
	if (counter > (target_freq >> 1))
		square = -1000;
	else
		square = 1000;
end

// Triangle Wave
always_comb begin
	if (counter > (target_freq >> 1))
		triangle = (counter - (target_freq >> 1)) << 4;
	else
		triangle = ((target_freq >> 1) - counter) << 4;
end

always_comb begin
	// Sawtooth
	case (wave_select)
		2'b00: sample = {sawtooth, 13'b0};
		
		2'b01: sample = {square, 13'b0};
		
		2'b10: sample = {triangle, 13'b0};
		
		2'b11: sample = 24'b0;
	endcase
end

always_ff @(posedge LRCLK or posedge SCLK) begin
	if (LRCLK)
		long <= {1'b0, sample, 7'b0}; // Load a new sample
	else
		long <= {long[30:0], 1'b0}; // Left Shift
end

assign DOUT = long[31];


endmodule