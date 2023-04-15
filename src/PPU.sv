//=======================================================
//  PPU
//  - This module represents the PPU (Picture Procesing Unit) of the NES architecture.
//    It is connected to its own personal BUS, and also must be connected to a VGA adapter 
//    at some point in the architecture.
//
//  - CPU BUS Section [$2000 - $3FFF] ~ Alot
//  - NOTE: This is mirrored every 8 bytes, meaning we only have a 3 bit address into
//    the control registers
//
//  - TODO:
//		Adapt for VGA
//
//=======================================================

module PPU (
	input CLK,
	input VIDEO_CLK,
	//input enable,
	
	// CPU BUS interface
	input [7:0] CPU_DATA_IN,
	input [2:0] CPU_ADDR,
	
	input CPU_wren, CPU_rden, // CPU wants to read / CPU wants to write
	
	output logic [7:0] CPU_DATA_OUT,
	
	//PPU BUS interface
	input [7:0] PPU_DATA_IN,
	
	output [7:0] PPU_DATA_OUT,
	output [13:0] PPU_ADDR,
	output PPU_WRITE, PPU_READ,
	
	// Video Output
	output             VGA_HS,
	output             VGA_VS,
	output   [ 3: 0]   VGA_R,
	output   [ 3: 0]   VGA_G,
	output   [ 3: 0]   VGA_B
);

//=======================================================
//  Control Regs
//=======================================================

logic [7:0] PPUCTRL, PPUMASK, PPUSTATUS, OAMADDR, OAMDATA, PPUSCROLL, PPUADDR, PPUDATA;

//=======================================================
//  State Machine
//=======================================================

logic [7:0] bingle;

always_ff @ (posedge CLK) begin
	PPU_ADDR <= 14'h1000;
	PPU_READ <= 1'b1;
	
	bingle <= PPU_DATA_IN;

end
//=======================================================
//  VGA Controller
//=======================================================

logic blank_n;

// This depends on our resolution http://tinyvga.com/vga-timing/640x480@60Hz
logic [9:0] drawx, drawy;

vga_controller vga_ctrl (.Clk(VIDEO_CLK), .Reset(1'b0), .hs(VGA_HS), .vs(VGA_VS), .blank(blank_n), .DrawX(drawx), .DrawY(drawy));
 
always_ff @ (posedge VIDEO_CLK) begin 
	if (blank_n) begin
		if (drawx > bingle[7:0]) begin
			VGA_R <= bingle[3:0]; // We expect this to be all 0s for now i think
			VGA_G <= bingle[3:0];
			VGA_B <= bingle[3:0];
		end 
		else begin
			VGA_R <= 4'b1111; 
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		
		end
		
	end
	
	else if (~blank_n) begin // Blanking interval
		VGA_R <= 4'b0000;
		VGA_G <= 4'b0000;
		VGA_B <= 4'b0000;
	end
end
	
endmodule