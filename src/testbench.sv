//=======================================================
//  Module Includes / Typedefs For Now
//=======================================================

typedef struct packed {
	logic [7:0] I;
	logic [7:0] A;
	logic [7:0] X;
	logic [7:0] Y;
	logic [7:0] S;
	logic [7:0] P;
} T65_Dbg;


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
#20 CPU_CLK = ~CPU_CLK;
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

logic [15:0]   ADDR_debug;
logic 			CPU_RW_n_debug;

T65_Dbg cpu_debug;

integer TestsFailed = 0;

//=======================================================
//  DUT Instantiationisnitanwo
//=======================================================

NES_ARCHITECUTRE NES(.MCLK(MCLK), .CPU_CLK(CPU_CLK), .CPU_RESET(reset), .cpu_debug(cpu_debug), .ADDR_debug(ADDR_debug), .CPU_RW_n_debug(CPU_RW_n_debug));

//=======================================================
//  Test Vectors
//=======================================================


initial begin: TEST_VECTORSs
reset = 1'b1; #10
reset = 1'b0; #2000
reset = 1'b1; 
end

endmodule