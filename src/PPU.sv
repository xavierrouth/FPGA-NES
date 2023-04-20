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
//  - PPU BUS Layout
//    [$0000-$0FFF] Pattern Table 0
//	   [$1000-$1FFF] Pattern Table 1
//
// 	[$2000-$23FF] Nametable 0
//		[$2400-$27FF] Nametable 1
//		[$2800-$2BFF] Nametable 2
//		[$2C00-$2FFF] Nametable 3
//
//		[$3000-$3EFF] Mirrors of Nametables (only until $2EFF)
//		
//		[$3F00-$3F1F] Palette RAM indexes
//		[$3F20-$3FFF] Mirrors of Palette Ram
//
//  - PPU BUS Read / Write
//		
// 
//
//  - OAM Layout
//
//  - TODO:
//		Adapt for VGA
//
//
//  - PAL vs NTSC:
//    pal has 5 clks per pixel, and ntsc has 4 clks per pixel
//
//=======================================================

//=======================================================
//  High Level Rendering Layout Overview:
//-------------------------------------------------------
//
//  Pattern Table (https://www.nesdev.org/wiki/PPU_pattern_tables)
//  - The ptable is an area of memory that defines the shapes of tiles.
//  - Also used to describe sprites
//  - Divided into two 256-tile sections, left [$0000-$0FFF], and right [$1000-$1FFF].
//  - The two planes are combined into a 2-bit number for each pixel, corresponding to a pixel's color.
//  - The second plane is the MSB.
//  
//  Addressing
//  - Need to use a 13 bit number to address into 0x1FFF locations (2^13 = 8192)
//  - This is broken down as follows:
//                       Controlled by PPUCTRL                                   0 low 1 upper
//		[1 -Mystery Bit][1 - Half of Pattern Table][4 - Tile Row][4 - Tile Column][1 - Bit Plane][3 - Fine Y offset / pixel row number]
//  
//-------------------------------------------------------
//
//  Name Table (https://www.nesdev.org/wiki/PPU_nametables)
//  - A nametable is a 1024 byte area of memory used to lay out background. 
//  - Each byte controls one 8x8 pixel character cell (tile), and each nametable has 30 rows of 32 tiles each.
//  - The first 960 / $3C0 Bytes contain the tiles, while the rest is used by the attribute table section.
// 
//  Mirroring
//	 - Who cares right now
// 
//
//  Render Evaluation
//  - 33 Times for each scanline (Each tile in the scanline)
//  - Fetch a nametable entry.
//  - Fetch the corresponding attribute table entry
//  - Increment the current VRAM address within the same row.
//  - Fetch the low byte from the pattern table
//  - Fetch the high byte of the pattern table (8 bytes higher)
//  - Calculate the palette indicies.
//
//-------------------------------------------------------
//
//	 Attribute Table (https://www.nesdev.org/wiki/PPU_attribute_tables)
//  - An attribute table is a 64-byte array at the end of each nametable that controls which palette is assigned to each part of the background.
//  - Each attribute table, 4 total starting at $23C0 ....
//  - Arranged as an 8x8 byte array
//  - Each Byte controls the palette of a 32x32 pixel or 4x4 tile part of the nametable and is divided into four 2-bit areas.
//  - [Topleft][Topright][Bottomleft][Bottomright]
//
//
//=======================================================

module PPU (
	input CLK,
	input VIDEO_CLK,
	input RESET,
	//input enable,
	
	// CPU BUS interface
	input [7:0] CPU_DATA_IN,
	input [2:0] CPU_ADDR,
	
	input CPU_wren, CPU_rden, // CPU wants to read / CPU wants to write
	
	output logic [7:0] CPU_DATA_OUT,
	output 	NMI,
	
	//PPU BUS interface
	input [7:0] PPU_DATA_IN,
	
	output [7:0] PPU_DATA_OUT,
	output [13:0] PPU_ADDR,
	output PPU_WRITE, PPU_READ, // PPU wants to read, ppu want to write
	
	// Video Output
	output             VGA_HS,
	output             VGA_VS,
	output   [ 3: 0]   VGA_R,
	output   [ 3: 0]   VGA_G,
	output   [ 3: 0]   VGA_B
);

//=======================================================
//  PPU Bus Control Quirk - Implement This Later?
//   Addr / Data bus is [13:0]
//	  the PPU muxes the lower eight VRAM address pins, also using them as the VRAM data pins,
//   this leads to each VRAM access taking two PPU cycles. 
//   Cycle 1: output VRAM address [13:0] on the PPU Bus, assert ALE signal and latch the bottom eight bits [7:0].
//   Cycle 2: output only upper six bits of the address, with latch providing lower eight bits. 
//            Our data will appear on the lower eight address pins
//
//=======================================================

// State Registers

logic [14:0] curr_vram_address;
logic [14:0] temp_vram_address;


logic [2:0] fine_x_scroll;

logic ppu_latch;

// When PPU is trying to write 
logic data_write_status;
logic data_read_status;

// TODO: Make sure that curr_Vram_address use is consistent
// PPU_BUS_ADDR is the external interface
assign PPU_BUS_ADDR = curr_vram_address[13:0];
logic [7:0] ppu_read_buffer;
logic [7:0] vram_addr_latched;


// CPU Interface
always_ff @ (posedge CLK) begin
	// rden and wren are never active at the same time
	//-------------CPU WRITE--------------------------
	if (CPU_wren) begin // CPU Write
		case (CPU_ADDR)
			// Write Only
			3'h0: begin 
				// Use a struct to make this easier??
				nmi_generate <= CPU_DATA_IN[7];
				sprite_size <= CPU_DATA_IN[5];
				background_ptable_addr <= CPU_DATA_IN[4]; // 0-> $0000 or 1 -> $1000
				sprite_ptable_addr <= CPU_DATA_IN[3];
				addr_increment <= CPU_DATA_IN[2];
				temp_vram_address[11:10] <= CPU_DATA_IN[1:0];
				
			end
			3'h1: PPUMASK <= CPU_DATA_IN;
			3'h3: OAMADDR <= CPU_DATA_IN;
			// Read Only
			3'h2: ;
			// Read / Write
			3'h4: begin
				// TODO: Fix this?
				// Increment OAMADDR after write
				OAMDATA <= CPU_DATA_IN;
				OAMADDR <= OAMADDR + 1;
			end
			// Write Twice
			3'h5: begin //PPUSCROLL
				if (ppu_latch == 1'b0) begin
					temp_vram_address[4:0] <= CPU_DATA_IN[7:3];
					fine_x_scroll <= CPU_DATA_IN[2:0];
					ppu_latch <= 1'b1;
				end
				else if (ppu_latch == 1'b1) begin
					temp_vram_address[9:5] <= CPU_DATA_IN[7:3];
					temp_vram_address[14:12] <= CPU_DATA_IN[2:0];
					ppu_latch <= 1'b0;
				end
			end
			3'h6: begin //PPUADDR
				if (ppu_latch == 1'b0) begin
					temp_vram_address[13:8] <= CPU_DATA_IN[5:0];
					temp_vram_address[14] <= 1'b0;
					ppu_latch <= 1'b1;
				end
				else if (ppu_latch == 1'b1) begin
					temp_vram_address[7:0] <= CPU_DATA_IN[7:0];
					curr_vram_address <= {temp_vram_address[14:8], CPU_DATA_IN[7:0]};
					 
					ppu_latch <= 1'b0;
				end
			end
			3'h7: begin //PPU_DATA
			
				// TODO: Confirm this should only write for one PPU cycle
				// PPU_ADDR should be set and outputting to BUS already, so just forward CPU data to PPU bus
				if (data_write_status == 1'b0) begin
					PPU_WRITE <= 1'b1; 
					PPU_DATA_OUT <= CPU_DATA_IN;
					data_write_status <= 1'b1;
					
					// Increment PPU_ADDR
					if (PPUCTRL[2]) 
						curr_vram_address <= curr_vram_address + 8'd32; // Increment 32
					else 
						curr_vram_address <= curr_vram_address + 1'd1; // Increment 1
				end
				else if (data_write_status == 1'b1) begin
					PPU_WRITE <= 1'b0; 
					// Open Bus / Don't Care I suppose
					data_write_status <= 1'b0;
				end
			end
		endcase // End Addr Case
	end // End Write
			
	//-------------CPU READ---------------------------
	else if (CPU_rden) begin // CPU Read
		
		case (CPU_ADDR)
			// Write Only
			3'h0: CPU_DATA_OUT <= 8'h0;
			3'h1: CPU_DATA_OUT <= 8'h0;
			// Read Only
			3'h2: begin	//Status
				// Output PPUSTATUS data
				
				CPU_DATA_OUT[7] <= status_vblank;
				CPU_DATA_OUT[6] <= sprite0_hit;
				CPU_DATA_OUT[5] <= ppu_sprite_eval;
				// The rest of the bus doesn't get updated
				
				//Clear latch for 2005 and 2006
				ppu_latch <= 1'b0;
				// Clear VBlank
				status_vblank <= 1'b0;
				
			end
			3'h3: ;
			3'h4: ;
			3'h5: ;
			3'h6: ;
			3'h7: begin
				//TODO: Implement different behavior for read buffer based on palette vs read form normal vram,
				//Maybe this can be abstracted away to a different module??
				CPU_DATA_OUT <= ppu_read_buffer;
				
				if (data_write_status == 1'b0) begin
					ppu_read_buffer <= PPU_DATA_IN;
					PPU_READ <= 1'b1;
					data_read_status <= 1'b1;
					if (PPUCTRL[2]) 
						curr_vram_address <= curr_vram_address + 8'd32; // Increment 32
					else 
						curr_vram_address <= curr_vram_address + 1'd1; // Increment 1
				end
				else if (data_read_status == 1'b1) begin
					//TODO: Should we update the read buffer on both steps of the read?
					//ppu_read_buffer <= PPU_DATA_IN;
					PPU_READ <= 1'b0;
					data_read_status <= 1'b0;
				end
				
			end
		endcase // End ADDR Case
	end // End read
end


//=======================================================
//  Control Regs - Meaning and Decoding (https://www.nesdev.org/wiki/PPU_registers)
//=======================================================

// TODO: Some of these are write-twice 16 bit regs
// These are all just an interface into the PPU, we should have separate variables / 
// registers to hold the correct values once written through these.
// I don't think these are real, these are just addresses.
logic [7:0] PPUCTRL, PPUMASK, PPUSTATUS, OAMADDR, OAMDATA, PPUSCROLL, PPUADDR, PPUDATA;

//=======================================================
// $2000 PPUCTRL - Write Only
// [7] - NMI Generate
// [6] - master/slave select (unused)
// [5] - Sprite size low: 8x8 high: 8x16
// [4] - Background Pattern Table Address
// [3] - Sprite Pattern table address
// [2] - VRAM address increment, low: (1 / going across) high: (32 / going down)
// [1:0] - Base nametable address #0: $2000, ... 
// [1:0] - Also the msb of the scrolling coordinates
//-------------------------------------------------------
// When master/slave select is low, the PPU gets the palette index from EXT pins which are grounded / 0.
// This should always be 0???. Yes I think its unused
//=======================================================

//TODO: Pack these as a struct?

logic nmi_generate;
logic sprite_size;
logic background_ptable_addr;
logic sprite_ptable_addr;
logic addr_increment;

//=======================================================
// $2001 PPUMASK - Write Only
// [7:5] - BGR color emphasis
// [4] - sprite enable
// [3] - background enable
// TODO: .... Who cares for now...
// [2] - VRAM address increment, low: (1 / going across) high: (32 / going down)
// [1:0] - Base nametable address #0: $2000, ... 
// [1:0] - Also the msb of the scrolling coordinates
//=======================================================

//=======================================================
// $2002 PPUSTATUS - Read Only
// [7:5] - BGR color emphasis
// [4] - sprite enable
// [3] - background enable
// TODO: .... Who cares for now...
// [2] - VRAM address increment, low: (1 / going across) high: (32 / going down)
// [1:0] - Base nametable address #0: $2000, ... 
// [1:0] - Also the msb of the scrolling coordinates
//=======================================================

logic status_vblank;
logic sprite0_hit;
logic ppu_sprite_eval;

//=======================================================
// PPUSCROLL - 16 bit - Write Twice
// Upper byte first, Valid addresses are $0000-$3FFF
//=======================================================

//=======================================================
// PPUADDR - 16 bit - Write Twice
// Upper byte first, Valid addresses are $0000-$3FFF
// To load address $2108:
//   lda #$21
//   sta PPUADDR
//   lda #$08
//   sta PPUADDR
// Read PPUSTATUS to reset the address latch
//=======================================================

//=======================================================
// PPUDATA - 8 bit - Read / Write
// After access, the video memory address will increment by an amount determined by bit 2 of $2000
// To load address $2108:
//   lda #$21
//   sta PPUADDR
//   lda #$08
//   sta PPUADDR
// Read PPUSTATUS to reset the address latch
//=======================================================

//=======================================================
//  Control Regs - Read / Write logic
//=======================================================

//=======================================================
//  Rendering Engine / State Machine
//=======================================================

// VRAM Data Tiles

logic [15:0] ptable_data; // Pattern Table Data
logic [7:0]  atable_data; // Attribute Table Data

// OAM
logic [63:0][3:0][7:0] OAM;

logic [9:0] cycle, scanline;

// Scanline and Cycle Engine
always_ff @ (posedge CLK) begin
	if (RESET) begin // Synchronous Reset Logic
		cycle <= 10'd0;
		scanline <= 10'd0;
	end
	
	if (cycle >= 10'd341) begin
		 cycle <= 10'd0; 
		 // Increment Scanline
		 if (scanline >= 10'd261) begin
			scanline <= 10'd0;
			//status_vblank <= 1'b1;
		 end
		 else begin
			scanline <= scanline + 1;
		 end
	end
	else begin
		// Increment Cycle
		cycle <= cycle + 1; 
	end
end

// Actually Do stuff with Scanline and Cycle
always_ff @ (posedge CLK) begin
	if (scanline == 241 & cycle == 1) begin
		if (nmi_generate) 
			NMI <= 1'b1; // When does this undo??
			
	// TODO: Do we have to wait 3 APU cycles before reseting so the CPU guarantes that it reads this on a CPU cycle?
	if (NMI) 
		NMI <= 1'b0;
	end


end

// Our Clock is 

assign PPU_ADDR = curr_vram_address[13:0];


//=======================================================
//  Framebuffer - Double Buffered Entire Frame, so 256 * 240 * 2 * 3 (bytes per pixel for each color?)
//  368,640 bytes. Where do we put it. 368kB.
//  Maybe we need a pallette so lets bytes per pixel, or maybe we just need like two lines buffers
//  1,638 Kb of OCM, so yes thats enough lol
//
//  Lets just do double buffered output as VGA colors.
//  256 * 2 * 2 = 1024 Bytes
//
//=======================================================


//=======================================================
//  VGA Controller
//=======================================================

//VGA Clock should be approx 107.5 MHz, / 5x Master.
logic blank_n;

// This depends on our resolution http://tinyvga.com/vga-timing/640x480@60Hz
logic [10:0] drawx, drawy;

vga_controller342 vga_controller (.Clk(VIDEO_CLK), .Reset(1'b0), .hs(VGA_HS), .vs(VGA_VS), .blank(blank_n), .DrawX(drawx), .DrawY(drawy));
 
logic [7:0] bingle;
assign bingle = 10'd200;

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