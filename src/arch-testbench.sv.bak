module testbench();

timeunit 1ps;	// Half clock cycle at 50 MHz
			
///////// Clocks /////////
logic  MCLK;
logic  LRCLK;
logic  SCLK;

logic reset;

logic [9:0] SW;

logic data_out;


integer TestsFailed = 0;

sgtl_audio_interface DUT(.MCLK(MCLK), .LRCLK(LRCLK), .SCLK(SCLK), .target_freq(SW[9:0]), .reset(reset), .DOUT(data_out));

always begin : MCLK_GENERATION
#1 MCLK = ~MCLK;
end

always begin : LRCLK_GENERATION
#128 LRCLK = ~LRCLK;
end

always begin : SCLK_GENERATION
#2 SCLK = ~SCLK;
end

initial begin: CLOCK_INITIALIZATION
    MCLK = 0;
	 LRCLK = 0;
	 SCLK = 0;
end 



initial begin: TEST_VECTORSs
reset = 1'b0; #10
reset = 1'b1; #256
reset = 1'b0; 
end

endmodule