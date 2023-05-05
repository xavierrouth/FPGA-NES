typedef struct packed {
	logic [15:0] PC; // PC, not sure which it is unclear
	logic [15:0] SP; // Stack Pointer
	logic [7:0] PF; // Processor Flags
	logic [7:0] X;
	logic [7:0] Y; 
	logic [7:0] A; 
} T65_Dbg;

module CPU_2A03 (
	input 			 CLK,
	input				 ENABLE,
	input 			 RESET,
	input 			 NMI_n,
	input 			 IRQ_n,
		
	input 	[7:0]  DATA_IN,
	
	
	output	[15:0] ADDR,
	output 	[7:0]  DATA_OUT,
	output 			 RW_n,
	
	output T65_Dbg  cpu_debug
);

//import T65_Pack::*;

// 6502-T65 Interface Signals
logic [7:0] DI, DO;

logic [23:0] A; // Top 8 bits probably not used

logic PAUSE;

assign PAUSE = 1'b0;

// 6502-T65 Debug Signals

logic [63:0] regs; //63:48 is unused maybe?? idk

assign cpu_debug.PC = regs[63:48];
assign cpu_debug.SP = regs[47:32];
assign cpu_debug.PF = regs[31:24];
assign cpu_debug.Y = regs[23:16];
assign cpu_debug.X = regs[15:8];
assign cpu_debug.A = regs[7:0];

T65 CPU(.mode(2'b00), 
		  .BCD_en(1'b0), 
		  .Res_n(~RESET), 
		  .Enable(ENABLE), 
		  .Clk(CLK),
		  .Rdy(~PAUSE),
		  .Abort_n(1'b1),
		  .IRQ_n(IRQ_n), // This was tied high
		  .NMI_n(NMI_n),
		  .SO_n(1'b1),
		  .R_W_n(RW_n), // High is read
		  .A(A), 
		  .DI(DI), 
		  .DO(DO), 
		  .Regs(regs)); //Everything else can be open I think

always_comb begin : data_route
	if (RW_n == 1'b0) // Write
		DI = DO;
	else
		DI = DATA_IN; // Read
end

assign DATA_OUT = DO;
assign ADDR = A[15:0];

endmodule

