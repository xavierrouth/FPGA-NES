typedef struct {
	logic [7:0] I;
	logic [7:0] A;
	logic [7:0] X;
	logic [7:0] Y;
	logic [7:0] S;
	logic [7:0] P;
} T65_Dbg;

module CPU_2A03 (
	input 			 CLK,
	input				 ENABLE,
	
	input 	[7:0]  DATA_IN,
	
	output	[15:0] ADDR,
	output 	[7:0]  DATA_OUT,
	output 			 RW_n,
	
	output T65_Dbg  cpu_debug
);

//import T65_Pack::*;

// 6502-T65 Interface Signals
logic [7:0] DI, DO;

logic [23:0] A;

logic R_W_n, Enable;

// 6502-T65 Debug Signals

logic [63:0] debug;

assign cpu_debug.A = debug[7:0];
assign cpu_debug.X = debug[15:8];

T65 CPU(.mode(2'b00), .BCD_en(1'b0), .Enable(ENABLE), .Clk(CLK), .R_W_n(R_W_n), .A(A), .DI(DI), .DO(DO), .Regs(debug));

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

