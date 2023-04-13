/**
module testbench();


//=======================================================
//  Timing and Clocks
//=======================================================

timeunit 1ps;	// Half clock cycle at 50 MHz

			
logic  MCLK;
logic  LRCLK;
logic  SCLK;
logic  CPU_CLK;

always begin : MCLK_GENERATION
#1 MCLK = ~MCLK;
end

always begin : CPU_CLK_GENERATION
#50 CPU_CLK = ~CPU_CLK;
end


initial begin: CLOCK_INITIALIZATION
    MCLK = 0;
	 CPU_CLK = 0;
end 


//=======================================================
//  WEGWEKJGKJ
//=======================================================


logic reset;

logic [9:0] SW;

logic data_out;

T65_Dbg cpu_debug;

integer TestsFailed = 0;

//=======================================================
//  DUT Instantiationisnitanwo
//=======================================================

NES_ARCHITECUTRE NES(.MCLK(MCLK), .CPU_CLK(CPU_CLK), .cpu_debug(cpu_debug));

//=======================================================
//  Test Vectors
//=======================================================


initial begin: TEST_VECTORSs
reset = 1'b0; #10
reset = 1'b1; #256
reset = 1'b0; 
end

endmodule
*/