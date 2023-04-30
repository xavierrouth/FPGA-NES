//=====================================================
//
//			Holds frame palette information
//			Supports dual port read, single port write (from PPU)
//
//
//
//
//
//

module FRAME_PALETTE ( input clk,

							  input rden,
							  input wren,
							  input render_rden,
							  input [7:0] data_in,
							  input [4:0] addr,
							  input [4:0] render_addr,
							  output logic [7:0] data_out,
							  output logic [7:0] render_data

);

logic [7:0] memory [32];

always_ff @ (posedge clk) begin

	if(wren)
	memory[addr] <= data_in;
	
	if(rden)
	data_out <= memory[addr];
	
	if(render_rden)
	render_data <= memory[render_addr];

end

endmodule