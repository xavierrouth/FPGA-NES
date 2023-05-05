//=======================================================
//  CHR_ROM
//  - This module represents the Game ROMs that are loaded into the NES from cartridges.
// 
//  - BUS Section [$4020 - $FFFF] ~ 49.120k Bytes
//    We only want to instantiate 49k Bytes of mem here, (NVM HOW WOULD QUARTUS KNOW???)
//
//  - TODO:
//		Mappers (This is why we have abstracted this memory away in the first place)
//  
//
//=======================================================

module CHR_ROM (
	input clk,
	input reset,

	input [7:0] prgmr_data,

	input [15:0] nes_addr,
	input [15:0] prgmr_addr,
	
	input nes_rden, prgmr_wren, // Read only from NES side, write only (maybe read) from NIOS loading side

	output logic [7:0] nes_data_out, // Data out to bus
	
	output [7:0] debug_out
);


logic [7:0] mem [8192]; // 2^13 (THE WHOLE CPU ADDRESS SPACE!!)

always_ff @ (posedge clk) begin
	/**
	if (~reset) begin
		// NES side
		if (nes_rden)
			nes_data_out <= mem[nes_addr];

		// NIOS prgmr Side
		if (prgmr_wren)
			mem[prgmr_addr] <= prgmr_data;
			
	end
	
	
	if (reset) 
		mem <= '{default:'0};
	*/
	
	if (nes_rden)
			nes_data_out <= mem[nes_addr];

	// NIOS prgmr Side
	if (prgmr_wren)
		mem[prgmr_addr] <= prgmr_data;
		
	
end

endmodule