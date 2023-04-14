typedef struct packed {
	logic [7:0] I; // IR or PC, not sure which it is unclear
	logic [7:0] A;
	logic [7:0] X;
	logic [7:0] Y;
	logic [7:0] S; // Stack Pointer
	logic [7:0] P; // Processor Flags
} T65_Dbg;

module CPU_2A03 (
	input 			 CLK,
	input				 ENABLE,
	input 			 RESET_n,
	
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

logic R_W_n, Enable, Rdy, NMI_n;

assign NMI_n = 1'b1;
assign Rdy = 1'b1;

// 6502-T65 Debug Signals

logic [63:0] debug; //63:48 is unused maybe?? idk

assign cpu_debug.A = debug[7:0];
assign cpu_debug.Y = debug[23:16];
assign cpu_debug.X = debug[15:8];
assign cpu_debug.P = debug[31:24];
assign cpu_debug.S = debug[39:32];
assign cpu_debug.I = debug[47:40];

T65 CPU(.mode(2'b00), 
		  .BCD_en(1'b0), 
		  .Res_n(RESET_n), 
		  .Enable(ENABLE), 
		  .Clk(CLK),
		  .Rdy(Rdy),
		  .Abort_n(1'b1),
		  .IRQ_n(1'b1),
		  .NMI_n(NMI_n),
		  .SO_n(1'b1),
		  .R_W_n(R_W_n), 
		  .A(A), 
		  .DI(DI), 
		  .DO(DO), 
		  .Regs(debug)); //Everything else can be open I think

always_comb begin : data_route
	if (RW_n == 1'b0)
		DI = DO;
	else
		DI = DATA_IN;
end

assign RW_n = R_W_n;
assign DATA_OUT = DO;
assign ADDR = A[15:0];

endmodule

