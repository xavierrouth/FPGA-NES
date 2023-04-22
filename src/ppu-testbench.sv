//=======================================================
//  Module Includes / Typedefs For Now
//=======================================================

module ppu_testbench();

//=======================================================
//  Timing and Clocks
//=======================================================

timeunit 1ps;	// Half clock cycle at 50 MHz

			
logic PPU_CLK;
logic VGA_CLK;
logic CPU_CLK;

// PPU runs twice as slow as VGA

always begin : VGA_CLK_GENERATION
#3 VGA_CLK = ~VGA_CLK;
end

always begin : PPU_CLK_GENERATION
#6 PPU_CLK = ~PPU_CLK;
end

always begin : CPU_CLK_GENERATION
#2 CPU_CLK = ~CPU_CLK;	
end


initial begin: CLOCK_INITIALIZATION
    VGA_CLK = 0;
	 PPU_CLK = 0;
	 CPU_CLK = 0;
end 


//=======================================================
//  WEGWEKJGKJ
//=======================================================


logic RESET;
//input enable,

// CPU BUS interface
logic [7:0] CPU_DATA_IN;
logic [2:0] CPU_ADDR;

logic CPU_wren, CPU_rden; // CPU wants to read / CPU wants to write

logic  [7:0] CPU_DATA_OUT;
logic 		 NMI_n;

logic debug_enable_nmi;

//PPU BUS interface
logic [7:0] PPU_DATA_IN;

logic [7:0] PPU_DATA_OUT;
logic [13:0] PPU_ADDR;
logic PPU_WRITE, PPU_READ; // PPU wants to read, ppu want to write

// Video Output
logic             VGA_HS;
logic             VGA_VS;
logic   [ 3: 0]   VGA_R;
logic   [ 3: 0]   VGA_G;
logic   [ 3: 0]   VGA_B;


integer TestsFailed = 0;

//=======================================================
//  DUT Instantiationisnitanwo
//=======================================================
PPU ppu_inst(.CLK(PPU_CLK), .CPU_CLK(CPU_CLK), .RESET(RESET), .VIDEO_CLK(VGA_CLK), .*);

//=======================================================
//  Test Vectors
//=======================================================


initial begin: TEST_VECTORS
debug_enable_nmi = 1'b1;
RESET = 1'b0; #10
RESET = 1'b1; #100
RESET = 1'b0; 
end

endmodule