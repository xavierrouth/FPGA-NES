module NES_ARCHITECUTRE (
	// Clocks
	input				 MCLK,
	input				 CPU_CLK,
	
	output T65_Dbg  cpu_debug
);


//=======================================================
//  Bus Architecture / Memory Mapped Logic
//=======================================================

logic [15:0] ADDR_BUS;
logic [7:0]  DATA_BUS;

// CPU Signals
logic [15:0] CPU_ADDR;
logic [7:0]  CPU_DATA_OUT;
logic 		 CPU_RW_n;
logic			 CPU_ENABLE;

assign CPU_ENABLE = 1'b1;

//=======================================================
//  Memory Instantiation
//=======================================================


//=======================================================
//  Module Instatiation
//=======================================================

CPU_2A03 inst(.CLK(CPU_CLK), .ENABLE(CPU_ENABLE), .DATA_IN(DATA_BUS), .ADDR(CPU_ADDR), 
				  .DATA_OUT(CPU_DATA_OUT), .RW_n(CPU_RW_n), .cpu_debug(cpu_debug));


endmodule