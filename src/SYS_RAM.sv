//=======================================================
//  SYS_RAM
//  - This module represents the internal system ram that the 6502 CPU uses, 
//    it contains mainly things like the zero page, and stack poitner, and it is important.
// 
//  - BUS Section [$0000 - $07FF] ~ 2k Bytes
//  - NOTE: [$0800-$0FFF], [$0800-$0FFF], [$0800-$0FFF] are all mirrors of the System Ram.
//  - This section is adressed by 000 [12:0] of the BUS_ADDR, We only need 11 bits to select 2kb,
//  - So we can actually just use BUS_ADDR[10:0], where [12:11] cause the mirroring.
//
//  - TODO:
//		What else goes here?
//
//  
//=======================================================

module SYS_RAM(
	input clk,
	//input enable,
	
	input [7:0] data_in,
	input [10:0] addr,
	
	input wren, rden,
	
	output logic [7:0] data_out
);

// Size is 2^11

logic [7:0] mem [2048];

always_ff @ (posedge clk) begin
	if (wren)
		mem[addr] <= data_in;
	if (rden)
		data_out <= mem[addr];
	
end

endmodule