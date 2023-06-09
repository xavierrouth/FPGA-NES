//=======================================================
//  PRG_ROM
//  - This module represents the Game ROMs that are loaded into the NES from cartridges.
// 
//  - BUS Section [$4020 - $FFFF] ~ 49.120k Bytes
//    We only want to instantiate 49k Bytes of mem here, (NVM HOW WOULD QUARTUS KNOW???)
//
//  - TODO:
//		Mappers (This is why we have abstracted this memory away in the first place)
//    Fix PRGROM size 
//
//=======================================================

module PRG_ROM (
	input clk,
	input reset,

	input [7:0] prgmr_data,

	input [15:0] nes_addr,
	input [15:0] prgmr_addr,

	input nes_rden, prgmr_wren, // Read only from NES side, write only (maybe read) from NIOS loading side

	output logic [7:0] nes_data_out // Data out to bus
	
);


/** CPU interrupt vectors at addresses:
$FFFA–$FFFB = NMI vector
$FFFC–$FFFD = Reset vector
$FFFE–$FFFF = IRQ/BRK vector
*/

//TODO: This should be cut down and have all address be subtracted from PRG_ROM base address. 
logic [7:0] mem [32768] /* synthesis ram_init_file = " supermario-prg.mif" */;
// 2^16 (THE WHOLE CPU ADDRESS SPACE!!)

always_ff @ (posedge clk) begin
	// NES side
	/**
	if (~reset) begin
		if (nes_rden)
			nes_data_out <= mem[nes_addr[14:0]];

		// NIOS prgmr Side
		if (prgmr_wren)
			mem[prgmr_addr[14:0]] <= prgmr_data;
	end
	if (reset) 
		mem <= '{default:'0};
	*/
	if (nes_rden)
			nes_data_out <= mem[nes_addr[14:0]];

	// NIOS prgmr Side
	if (prgmr_wren)
		mem[prgmr_addr[14:0]] <= prgmr_data;
	
end

endmodule