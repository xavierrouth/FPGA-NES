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
							  input reset,

							  input rden,
							  input wren,
							  input render_rden,
							  input [7:0] data_in,
							  input [4:0] addr,
							  input [4:0] render_addr,
							  output logic [7:0] data_out,
							  output logic [7:0] render_data

);

logic [7:0] memory [32]; // This goes up to $20

logic [4:0] addr_mirrored;
logic [4:0] render_addr_mirrored;

// handle mirroring
always_comb begin
	case (addr)
		5'h10: addr_mirrored = 5'h00;
		5'h14: addr_mirrored = 5'h04;
		5'h18: addr_mirrored = 5'h08;
		5'h1C: addr_mirrored = 5'h0C;
		default: addr_mirrored = addr;
	endcase
	case (render_addr)
		5'h10: render_addr_mirrored = 5'h00;
		5'h14: render_addr_mirrored = 5'h04;
		5'h18: render_addr_mirrored = 5'h08;
		5'h1C: render_addr_mirrored = 5'h0C;
		default: render_addr_mirrored = render_addr;
	endcase
end

//4th entry needs to get mirrored down
// IE $3F04 goes to 
always_ff @ (posedge clk) begin

	if(wren)
		memory[addr_mirrored] <= data_in;
	
	if(rden)
		data_out <= memory[addr_mirrored];
	
	if(render_rden)
		render_data <= memory[render_addr_mirrored];

end

endmodule