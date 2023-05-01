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
//  - Increment the activeent VRAM address within the same row.
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
	input CLK, // 5.375 MHz or something
	input CPU_CLK, // 1.7 or something
	input VIDEO_CLK, // 10.75 MHz (twice as fast)
	input RESET,
	input ENABLE,
	
	input debug_enable_nmi,
	
	// CPU BUS interface
	input [7:0] CPU_DATA_IN,
	input [2:0] CPU_ADDR,
	
	input CPU_wren, CPU_rden, // CPU wants to read / CPU wants to write
	
	output logic [7:0] CPU_DATA_OUT,
	output logic		 NMI_n,
	
	// DMA Interface
	input DMA_write,
	input [7:0] DMA_address,
	input [7:0] DMA_data,
	
	// PPU BUS interface
	input [7:0] PPU_DATA_IN,
	
	output logic [7:0] PPU_DATA_OUT,
	output logic [13:0] PPU_ADDR,
	output logic PPU_WRITE, PPU_READ, // PPU wants to read, ppu want to write
	
	// FRAME PALETTE interface
	output logic [4:0] FRAME_PALETTE_RENDER_ADDR,
	output logic FRAME_PALETTE_RENDER_READ,
	input logic [7:0] FRAME_PALETTE_RENDER_DATA_IN,
	
	// Video Output
	output logic          VGA_HS,
	output logic          VGA_VS,
	output logic [ 3: 0]   VGA_R,
	output logic [ 3: 0]   VGA_G,
	output logic [ 3: 0]   VGA_B
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
typedef struct packed {
	logic [2:0] fine_y; 
	logic       nametable_y;
	logic 		nametable_x;
	logic [4:0] coarse_y;
	logic [4:0] coarse_x; 
} loopy_reg;


loopy_reg active_vram_address;
loopy_reg temp_vram_address;

logic [2:0] fine_x;

logic ppu_latch;

// PPU_BUS_ADDR is the external interface
logic [7:0] ppu_read_buffer;
logic [7:0] ppu_write_buffer;
logic [13:0] vram_addr_buffer;

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
logic addr_increment; // 0 is 1, 1 is 32

//=======================================================
// $2001 PPUMASK - Write Only
// [7:5] - BGR color emphasis
// [4] - sprite enable
// [3] - background enable
// TODO: .... Who cares for now...

//=======================================================
//TODO: Have BGR color emphasis shift the vga output values left

logic [2:0] bgr_color_emphasis;
logic sprite_render_enable;
logic background_render_enable;

//=======================================================
// $2002 PPUSTATUS - Read Only
// [7] - Vertical blank has started (this is just based on NMI)
// [6] - Sprite 0 Hit
// [5] - sprite evaluation has started
// [4:0] - Open bus / don't care
//=======================================================

// TODO: Figure out if these are actually always the same (nmi occured and status_vblank), or if they need to be seperated.
// Does systemverilog have variable aliases?? What would the use case for those be?
logic status_vblank;

logic sprite0_hit;
logic sprite_overflow;

//=======================================================
// $2003 OAMADDR - Write
// Literally just write an address I think
//=======================================================
logic [7:0] oam_address;

//=======================================================
// $2004 OAMDATA - Read / Write
// Literally just write an address I think
// Writes will increment OAMADDR after the write; 
// reads during vertical or forced blanking return the value from OAM at that address but do not increment
// reads during rendering are bad, TODO (expose internal OAM access during sprite evaluation and loading)
//=======================================================
logic [7:0] oam_data;

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

// CPU REQUEST FLAGS
logic cpu_write_request;
logic cpu_read_request;
logic cpu_load_vram_request;
logic cpu_inc_vram_request;
logic cpu_nmi_clear_request;


//assign nmi_generate = debug_enable_nmi;
// CPU Interface
always_ff @ (posedge CPU_CLK) begin
	// rden and wren are never active at the same time
	if (RESET) begin
		cpu_write_request <= 1'b0;
		cpu_read_request <= 1'b0;
		cpu_inc_vram_request <= 1'b0;
		cpu_nmi_clear_request <= 1'b0;
		cpu_load_vram_request <= 1'b0;
		ppu_latch <= 1'b0;
		OAM <= '{default:'0};
	end
	else if (DMA_write) begin
		OAM[DMA_address] <= DMA_data;
	end
	//-------------CPU WRITE--------------------------
	else if (CPU_wren) begin // CPU Write
		case (CPU_ADDR)
			// Write Only
			3'h0: begin 
				// Use a struct to make this easier??
				nmi_generate <= CPU_DATA_IN[7];
				sprite_size <= CPU_DATA_IN[5];
				background_ptable_addr <= CPU_DATA_IN[4]; // 0-> $0000 or 1 -> $1000
				sprite_ptable_addr <= CPU_DATA_IN[3];
				addr_increment <= CPU_DATA_IN[2];
				temp_vram_address.nametable_y <= CPU_DATA_IN[1];
				temp_vram_address.nametable_x <= CPU_DATA_IN[0];
			end
			3'h1: begin
				bgr_color_emphasis <= CPU_DATA_IN[7:5];
				sprite_render_enable <= CPU_DATA_IN[4];
				background_render_enable <= CPU_DATA_IN[3];
			end
			3'h3: oam_address <= CPU_DATA_IN;
			// Read Only
			3'h2: ;
			// Read / Write
			3'h4: begin
				// TODO: Fix this?
				// Increment OAMADDR after write
				// Multiple drivers sigh
				OAM[oam_address] <= CPU_DATA_IN;
				oam_address <= oam_address + 1;
			end
			// Write Twice
			3'h5: begin //PPUSCROLL
				if (ppu_latch == 1'b0) begin
					temp_vram_address.coarse_x <= CPU_DATA_IN[7:3];
					fine_x <= CPU_DATA_IN[2:0];
					ppu_latch <= 1'b1;
				end
				else if (ppu_latch == 1'b1) begin
					temp_vram_address.coarse_y <= CPU_DATA_IN[7:3];
					temp_vram_address.fine_y <= CPU_DATA_IN[2:0];
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
					temp_vram_address <= {temp_vram_address[14:8], CPU_DATA_IN[7:0]};
					ppu_latch <= 1'b0;
					cpu_load_vram_request <= ~cpu_load_vram_request;
				end
			end
			3'h7: begin //PPU_DATA
				// Request that a write occur
				ppu_write_buffer <= CPU_DATA_IN;
				cpu_write_request <= ~cpu_write_request;
				// Request that vram be incremented
				cpu_inc_vram_request <= ~cpu_inc_vram_request;
			end
		endcase // End Addr Case

	end // End Write
			
	//-------------CPU READ---------------------------
	else if (CPU_rden) begin // CPU Read
		case (CPU_ADDR)
			// Write Only
			3'h0: ;
			3'h1: ;
			// Read Only
			3'h2: begin	//Status
				
				//Clear latch for 2005 and 2006
				ppu_latch <= 1'b0;
				
				// Request NMI clear
				cpu_nmi_clear_request <= ~cpu_nmi_clear_request;
			end
			3'h3: ;
			3'h4: ;
			3'h5: ;
			3'h6: ;
			3'h7: begin
				cpu_read_request <= ~cpu_read_request;
				//TODO: This updates too soon, this needs to update later, just think about it
				ppu_read_buffer <= PPU_DATA_IN;
			end
		endcase // End ADDR Case
	end // End read
end

always_comb begin
	//-------------CPU READ---------------------------
	// Default Values
	CPU_DATA_OUT = 8'h0; //TODO: What should the default of this be?
	
	if (CPU_rden) begin // CPU Read
		case (CPU_ADDR)
			// Write Only
			3'h0: ;
			3'h1: ;
			// Read Only
			3'h2: begin	//Status
				// Output PPUSTATUS data
				CPU_DATA_OUT[7] = status_vblank;
				CPU_DATA_OUT[6] = sprite0_hit;
				CPU_DATA_OUT[5] = sprite_overflow;
			end
			3'h3: ;
			3'h4: CPU_DATA_OUT = OAM[oam_address]; // OAM Data
				
			3'h5: ;
			3'h6: ;
			3'h7: begin
				if (CPU_ADDR >= 14'h3F00)
					CPU_DATA_OUT = PPU_DATA_IN;
				else
					CPU_DATA_OUT = ppu_read_buffer;
			end
		endcase // End ADDR Case
	end // End read
end

//=======================================================
//  Cycle and Scanline Engine
//=======================================================

// Scanline and Cycle Engine (Very similar to VGA controller)

logic [9:0] cycle, scanline, next_cycle, next_scanline;
logic [9:0] scanline_intermediate;
logic extra_cycle_latch;
logic extra_cycle;

assign scanline = scanline_intermediate + 1;

parameter [9:0] cycle_count = 10'd340; //
parameter [9:0] scanline_count = 10'd261;

logic ppu_vs, ppu_hs;

always @(posedge CLK) begin
	if (RESET) begin
		cycle <= 10'd0;
		scanline_intermediate <= 10'd0;
		next_cycle <= 10'd0;
		next_scanline <= 10'd0;
		ppu_vs <= 1'b0;
		ppu_hs <= 1'b0;
		extra_cycle_latch <= 1'b0;
	end
	else begin
		if (next_cycle == (cycle_count + extra_cycle)) begin
			//extra_cycle_latch <= ~extra_cycle_latch;
			next_cycle <= 10'd0;
			if (next_scanline == scanline_count)
				next_scanline <= 10'd0;
			else 
				next_scanline <= next_scanline + 1;
		end
		else
			next_cycle <= next_cycle + 1;
			
		cycle <= next_cycle;
		scanline_intermediate <= next_scanline;
	end
	
end

//=======================================================
//  Rendering Logic Signals
//=======================================================

// PPU HANDLE FLAGS (These mirror the CPU request flags)
logic ppu_write_handle;
logic ppu_read_handle;
logic ppu_load_vram_handle;
logic ppu_inc_vram_handle;
logic ppu_nmi_clear_handle;

// PPU REQUEST FLAGS (These are things that the PPU wants to do also, they are different from handling requests the CPU makes)
// Every cycle these are high, they happen.
logic ppu_write_request;
logic ppu_read_request;
logic ppu_load_vram_request;
logic ppu_nmi_set_request;
logic ppu_nmi_clear_request;

// Copy horizontal and vertical bits respecively
logic ppu_hcopy_vram_request;
logic ppu_vcopy_vram_request;
logic ppu_hinc_vram_request;
logic ppu_vinc_vram_request;


// Actualy linebuffer (this gets inferred as ram yay :))

logic [255:0][5:0] linebuffer [2];

// Indicies into linebuffer
logic ppu_linebuffer;
logic vga_linebuffer;
assign vga_linebuffer = ~ppu_linebuffer;

logic render_enable;
// TODO: This is just pulled high for now for testing
assign render_enable = background_render_enable | sprite_render_enable;

assign extra_cycle = extra_cycle_latch & render_enable;

logic [2:0] counter;
logic [1:0] attribute_counter;
logic [9:0] cycleminone;
assign cycleminone = cycle-1;
assign counter = ((cycle - 1) % 8); // This is plus one because all our reads and writes are delayed

assign attribute_counter = {scanline[4], cycleminone[4]}; //Divides each line by 8 32 pixel sections, determines if first or second 16 bits

// TODO:
// Even / Odd Frames (might fix scrolling issue)

//=======================================================
//  NMI Logic Always Comb
//=======================================================
always_comb begin
	// Start of vertical Blanking
	ppu_nmi_set_request = 1'b0;
	ppu_nmi_clear_request = 1'b0;
	
	
	if (scanline == 241) begin
		if (cycle == 1) begin
			ppu_nmi_set_request = 1'b1;
		end
	end
	// End of Vertical Blanking
	if (scanline == 261) begin 
		if (cycle == 1) begin
			ppu_nmi_clear_request = 1'b1;
		end
	end 
end

//=======================================================
//  PPU Internal Data 
//=======================================================

// Always_comb for doing stuff

logic [4:0] palette_idx; // idx into some palette
logic [4:0] sprite_idx;
logic [4:0] background_idx;
logic [5:0] color_idx; // The color data retrieved from the palette?

logic [1:0] palette_data_in; // This is the awerl;gerbjka;

// VRAM Data Tiles

logic [15:0] ptable_data [2]; // Pattern Table Data
logic [7:0] ptable_data_temp [2];
logic [7:0]  atable_byte; // Attribute Table Data
logic [1:0]  atable_bits;
logic [7:0]  ntable_byte; // Unclear if this is needed
logic [15:0] palette_data [2];

// OAM
logic [3:0][7:0] OAM [64];

logic [3:0][7:0] sprites [8]; // This is secondary OAM

// Each sprite gets a pair
logic [7:0] sprite_shifters [8][2]; // This contains the tile data of the sprites for a scanline
										   // This needs to get loaded from a PPU fetch during sprite evaluation
logic [7:0] sprite_attributes [8]; // This contains the attribute data of the sprites
logic [7:0] sprite_x_position [8]; // This counts down the x position until the sprite becomes active

// Misc 
logic [7:0] oam_clear_counter;

logic [5:0] sprite_oam_idx;
logic [1:0] sprite_byte_idx;
logic [3:0] sprite_counter;
logic [5:0] sprite_fetch_idx;

// This is the palette idx
// First bit chooses foreground vs background

//=======================================================
//  Background vs Foreground Pixel Composition (Rendering Logic Always Comb Pt. 2)
//=======================================================

always_comb begin
	// Default Values
	sprite_idx = 5'b00;
	background_idx = 5'b00;
	palette_idx = 5'b00;
	// Do foreground
	
	for (int i = 0; i < 8; i++) begin
		// If any of the counters are 0 then lets draw the x value of that sprite
		if (sprite_x_position[i] == 0) begin
			// We need to figure out how to do this with priority going to the first one to resolve multiple drivers
			// TODO: Make this use sprite palette eventually, but for now just use some random tile palette
			sprite_idx = {1'b0, palette_data[1][15-fine_x], palette_data[0][15-fine_x], sprite_shifters[i][1][7], sprite_shifters[i][0][7]}; // Draw the leftmost bit of this
		end
	
	end
	
	
	// If there are no sprites at all, then our background pixel color pallete idx is just:
	// {1'b0, palette_data[1][15-fine_x], palette_data[0][15-fine_x], ptable_data[1][15-fine_x], ptable_data[0][15-fine_x]};
	// The full index into our frame pallete, composed of the palette we want, and then the color in that palette.
	background_idx = {1'b0, palette_data[1][15-fine_x], palette_data[0][15-fine_x], ptable_data[1][15-fine_x], ptable_data[0][15-fine_x]};
	
	// TODO: Implement actual priortity and flipped drawing here
	if (sprite_idx[1:0] == 2'b00) // DEBUG: I'm thinking this is ALWAys true OOPS when it shuoldn't be
		palette_idx = background_idx;
	else
		palette_idx = sprite_idx;
	
	// I think these are always the same, but we can draw different stuff here if we want to debug
	//palette_idx = {1'b0, palette_data_in, ptable_data[1][15-fine_x], ptable_data[0][15-fine_x]};
	FRAME_PALETTE_RENDER_ADDR = palette_idx;

	//color_idx = {ptable_data[1][15-fine_x], ptable_data[0][15-fine_x]}; 
	//color_idx = ntable_byte;
	color_idx = FRAME_PALETTE_RENDER_DATA_IN[5:0];

end



//=======================================================
//  DMA and OAM handling
//=======================================================

// This happens in the CPU interfacing bl walys__ff


//=======================================================
//  Rendering Logic Always Comb
//=======================================================

always_comb begin
	// ========== Default Values =========================
	
	ppu_read_request = 1'b0;
	FRAME_PALETTE_RENDER_READ = 1'b0;
	//FRAME_PALETTE_RENDER_ADDR = 4'd0;
	
	// Weird Register Increments
	ppu_hinc_vram_request = 1'b0;
	ppu_vinc_vram_request = 1'b0;
	ppu_hcopy_vram_request = 1'b0;
	ppu_vcopy_vram_request = 1'b0;
	
	//PPU_ADDR = active_vram_address[11:0];
	PPU_ADDR = active_vram_address;
	if (~render_enable) begin
		;//PPU_ADDR = active_vram_address;
	// IF RENDERING ENABLED:
	//======== VISIBLE SCANLINES (0-239) ==============
	end else if (scanline <= 10'd239 | scanline == 10'd261) begin
		// ----------CYCLES 1-256 and CYCLES 321-338
		if ((cycle >= 1 & cycle <= 256) | (cycle >= 321 & cycle < 338)) begin //TODO: Less than 338?
		
			 FRAME_PALETTE_RENDER_READ = 1'b1;
			// ===========  DO SOME FETCHING HERE  ==============
			case (counter) // Case coutner
				// Fetch nametable byte
				3'd0: begin
					PPU_ADDR = {2'b10, active_vram_address[11:0]};
					ppu_read_request = 1'b1;
				end
				3'd1: begin
					PPU_ADDR = {2'b10, active_vram_address[11:0]};
					ppu_read_request = 1'b1;
				end
				// Fetch attribute table byte
				3'd2: begin
					PPU_ADDR = {2'b10, active_vram_address[11:10], 4'b1111, active_vram_address[9:7], active_vram_address[4:2]};
					ppu_read_request = 1'b1;
				end
				3'd3: begin
					PPU_ADDR = {2'b10, active_vram_address[11:10], 4'b1111, active_vram_address[9:7], active_vram_address[4:2]};
					ppu_read_request = 1'b1;
				end
				3'd4: begin
					PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b0, active_vram_address.fine_y}; //??
					ppu_read_request = 1'b1;
				end
				
				3'd5: begin
					PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b0, active_vram_address.fine_y}; //??
					ppu_read_request = 1'b1;
				end
				// fetch pattern tile high 
				3'd6: begin
					PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b1, active_vram_address.fine_y}; //?? + 8 from pattern table tile low
					ppu_read_request = 1'b1;
				end
				3'd7: begin
					PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b1, active_vram_address.fine_y}; //?? + 8 from pattern table tile low
					ppu_read_request = 1'b1;
					ppu_hinc_vram_request = 1'b1;
				end
			endcase // End case counter
			
			if (cycle == 10'd256) begin
				// This needs to increment the veritcal position in v, the effective Y scroll coordinate
				ppu_hinc_vram_request = 1'b1;
				ppu_vinc_vram_request = 1'b1;
			end
			
			
			
			//================= BACKGROUND PIXEL COMPOSITION=====================
			

		end
		if (cycle == 257) begin
			// Load shifters
			ppu_hcopy_vram_request = 1'b1;
		end
		// ----------CYCLES 257-320
		//================= SPRITE STUFF ========================
		if (cycle >= 257 & cycle <= 320) begin
			// sprite_fetch_idx is updated by our always_ff logic
			// the 1th index is the one that contains the ptable entry
			// for 8x8 sprites
			// TODO: Change this for 8x16 sprites? UGH
			// use ppuctrl_bit
			
			// fetch lower byte of ptable
			if (counter <= 3) begin
				PPU_ADDR = {1'b0, background_ptable_addr, sprites[sprite_fetch_idx][1], 1'b0, sprites[sprite_fetch_idx][0] - scanline}; //??
				ppu_read_request = 1'b1;
			// fetch upper byte of ptable
			end else if (counter >= 4) begin
				PPU_ADDR = {1'b0, background_ptable_addr, sprites[sprite_fetch_idx][1], 1'b1, sprites[sprite_fetch_idx][0] - scanline}; //??
				ppu_read_request = 1'b1;
			end
			// Low parts need to be formed based on the current scanline as well as the y value of the sprite
			// Lets just subtract them maybe??
			// sprites[sprite_fetch_idx][1] replaces ntable_byte
		end
	end // end if rendering enabled
	
	//======= POST RENDER SCANLINE (240) ==============
	// Do Nothing
	//======= POST RENDER SCANLINE (241-260) ==============
	if (scanline == 241) begin
		if (cycle == 1) begin
			;//ppu_nmi_set_request = 1'b1;
		end
	end
	//======== PRE RENDER SCANLINE (261) ==============
	if (scanline == 261) begin 
		if (cycle == 1)
			;// End of Vertical Blanking
			//ppu_nmi_clear_request = 1'b1;
		else if (cycle >= 280 & cycle <= 304) begin
			// Reload vertical scroll bits TODO: Only if rendering is enabled?
			if (render_enable)
				ppu_vcopy_vram_request = 1'b1;
		end
	end // End Pre Render Scanelin
	// if rendering_enable
end


//=======================================================
//  Rendering Logic Always FF
//=======================================================


// Always_ff For doing stuff
always_ff @ (posedge CLK) begin
	if (RESET) begin
		ppu_linebuffer <= 1'b0;
		ntable_byte <= 8'd0;
		oam_clear_counter <= 8'd0;
		sprite_oam_idx <= 6'd0;
		sprite_byte_idx <= 2'd0;
		sprite_counter <= 4'd0;
		sprite_fetch_idx <= 6'd0;
	end else begin // NOT RESET
		if (render_enable) begin
			// Color_idx decided by the composition logic.		
			linebuffer[ppu_linebuffer][cycle] <= color_idx;
			
			//================= Visible Scanlines =====================
			if (scanline <= 10'd239 | scanline == 10'd261) begin
				//================= BACKGROUND RENDERING=====================
				if ((cycle >= 1 & cycle <= 256) | (cycle >= 321 & cycle < 338)) begin 
					
					// Update Shifters:
					
					// Shift Pattern Table Data 
					ptable_data[1] <= {ptable_data[1][14:0], 1'b0}; //shift pattern data
					ptable_data[0] <= {ptable_data[0][14:0], 1'b0};
					
					// Palette Data Shifters
					palette_data[1] <= {palette_data[1][14:0], 1'b0}; 
					palette_data[0] <= {palette_data[0][14:0], 1'b0};
					
					case (counter)
						// Fetch nametable byte
						3'd0: begin
							
							ptable_data[1][7:0] <= ptable_data_temp[1];
							ptable_data[0][7:0] <= ptable_data_temp[0];
							
							// Load attribute table data / palette data 
							// We need to use coarse_x and coarse_y when we load atable_byte, not after
							palette_data[1][7:0] <= {8{atable_bits[1]}};
							palette_data[0][7:0] <= {8{atable_bits[0]}};
							
						end
						// Fetch nametable byte
						3'd1: ntable_byte <= PPU_DATA_IN; // Sometimes dumym fetches but don't load data
						3'd2: ;
						3'd3: begin
							case ({active_vram_address.coarse_x[1], active_vram_address.coarse_y[1]})
								2'b00: begin // upper Left
									atable_bits[1] <= {PPU_DATA_IN[1]};
									atable_bits[0] <= {PPU_DATA_IN[0]};
								end 
								2'b10: begin // upper right
									atable_bits[1] <= {PPU_DATA_IN[3]};
									atable_bits[0] <= {PPU_DATA_IN[2]};
								end 
								2'b01: begin // bottom left
									atable_bits[1] <= {PPU_DATA_IN[5]};
									atable_bits[0] <= {PPU_DATA_IN[4]};
								end 
								2'b11: begin // bottom right
									atable_bits[1] <= {PPU_DATA_IN[7]};
									atable_bits[0] <= {PPU_DATA_IN[6]};
								end 
							endcase
							atable_byte <= PPU_DATA_IN;
						end
						// fethc parttern table low 
						3'd4: ;
						3'd5: ptable_data_temp[0] <= PPU_DATA_IN;
						// fetch pattern tile high 
						3'd6: ;
						3'd7: ptable_data_temp[1] <= PPU_DATA_IN;
					endcase
				end // End visible cycles
				
				//================= SPRITE RENDERING=====================
				//--------HANDLE SPRITES FOR CURRENT SCANLINE-------------
				if ((cycle >= 1 & cycle <= 256)) begin
					// Oh my we have lots of work to do, everything we need should be in scanline stuff before,
					// Bascially lets just shift the registers at the correct times and let the priority mux and 
					// composition logic in the alway_comb handle the difficult stuff
					
					// For each sprite, in parallel (Generate / for loop), we have to do:
					
					// If any x values aren't 0, then we decrement them
					// If they are 0, then the sprite is "active" and we can start shifting the data to the left.
					
					
					for (int i = 0; i <8; i++) begin
						// X coordinate
						if (sprite_x_position[i] > 0)
							sprite_x_position[i] <= sprite_x_position[i] - 1;
						else if (sprite_x_position[i] == 0) begin
							sprite_shifters[i][0] <= {sprite_shifters[i][0][6:0], 1'b0}; // Left shift
							sprite_shifters[i][1] <= {sprite_shifters[i][1][6:0], 1'b0}; // Left shift
							// Once the sprite is done, 11 is the background color already, so yay!
							// Or is 00 the background color... TODO: FIX ME
						end
					end
					
					
				
				end
				//------DO SPRITE EVALUATION FOR NEXT SCANLINE------------:
				
				// Basically clear all of our counters
				if (cycle == 0) begin
					sprite_oam_idx <= 6'd0;
					sprite_byte_idx <= 2'd0;
					sprite_counter <= 0;
					sprite_fetch_idx <= 1'b0;
					oam_clear_counter <= 0;
				end
				// Clear Secondary OAM
				if (cycle > 0 && cycle <= 64) begin
					oam_clear_counter <= oam_clear_counter + 1;
					sprites[oam_clear_counter] <= 8'hFF;
					
				end
				// Sprite Evaluation
				if (cycle > 64 && cycle <= 256) begin
					// Read OAM on odd cycles
					// Write sprites on Even cycles
					if (sprite_counter < 8) begin
						// Check all sprites in OAM
						sprites[sprite_counter][0] <= OAM[sprite_oam_idx][0]; // Read Y coordinate
						
						// Check if Y coordinate is in Range
						// diff = (scanline - OAM[sprite_oam_idx][0]);
						
						if (((scanline - OAM[sprite_oam_idx][0]) >= 0) && ((scanline - OAM[sprite_oam_idx][0]) < (8 + 8 * sprite_size ))) begin
							// Found Sprite, so load it and increment.
						   sprites[sprite_counter] <= OAM[sprite_oam_idx];
							sprite_counter <= sprite_counter + 1;
						end
						
						// Increment N
						sprite_oam_idx <= sprite_oam_idx + 1;
						
					end
				end
				// TODO: DO SPRITE OVERFLOW
				// If we had over? IDK if this matters 
				if (sprite_counter > 8) begin
				
					sprite_overflow <= 1'b1;
				end
				// At this point we have all our sprites for the next scanline loaded into sprites[]
				// Now we have to load them into the registers used for the active scanline, so that we can draw them correctly
				// We also need to do fetches from ptable data in order to figure out what they actually are.
				// Sprite Fetches
				if (cycle > 256 && cycle <= 320) begin
					// 8 Cycles per sprite, 8 Sprites (320-256 = 64)
					case (counter) // Todo: figure out what this should be
						// THIS IS ALL COMPLETELY ARBITRARY LOL 
						// [7:0] sprite_shifters [8];
						// [7:0] sprite_attributes [8];
						// [7:0] sprite_x_position [8];
						3'd0: sprite_attributes[sprite_fetch_idx] <= sprites[sprite_fetch_idx][2];
						3'd1: sprite_x_position[sprite_fetch_idx] <= sprites[sprite_fetch_idx][3];
						3'd2: sprite_shifters[sprite_fetch_idx][0] <= PPU_DATA_IN; 
						3'd3: ;
						3'd4: ; // Set address according to sprites[sprite_fetch_idx][1];
						3'd5: ;
						3'd6: sprite_shifters[sprite_fetch_idx][1] <= PPU_DATA_IN; 
						3'd7: sprite_fetch_idx <= sprite_fetch_idx + 1;
					endcase
				end
				// At this point all our sprites for the next scanline that is about to happen are prepared, 
				// so good job us! Yay! Yay! hooray!! yay!
				//do something?
				if (cycle > 320) begin
					;
				end
			end //================= END VISIBLE SCANLINES =====================
			
			if (cycle == 10'd340) begin
				ppu_linebuffer <= ~ppu_linebuffer;
			end
			// Swap linebuffer once a scanline
			if (cycle == 257) begin
				// TODO: Do shifters stuff?
				;
			end
			
		end // End render enable
		// PRE RENDER SCANLINE
		if (scanline == 261) begin 
			if (cycle == 1)
				sprite_overflow <= 1'b0;
		end
	end
end
		
 
//============ CPU-PPU ASYNC ==================================================================================
// There are Various parts of the NES that are driven both by the PPU and by the CPU,
// this results in all sorts of weird behavior, when one side once to do something and other
// doesn't know. SystemVerilog and HDL constrains us by not allowing 'multiple drivers',
// therefore we must handle it using flags generated by always_comb blocks.
//
// THIS IS SO FUCKY -- DEPRECEATED:
//
// Sometimes we only want things to happen once per CPU cycle (incrementing vram address), 
// The problem with our proposed setup is that the inc_vram flag will be set the whole time,
// and that we won't be able to 'unset' the flag because it is controlled by CPU.
//
// in order to handle this, we need to:
// 	read that a request is requested from the CPU
//    handle the request, but set a cooldown that counts down according to the PPU clock
//    this seems so fucking annoying, but maybe it will work
//
//
// THIS IS REALLY COOL:
//
// We need the CPU to request that things happen on the PPU, reading / writing to registers sets various 'CPU' flags.
// These requests are seen by the PPU, and then handled. In order to know that the request has already been handled, 
// the PPU has a flag of its own, that it sets upon handling a request. The PPU then only cares about the xor of both flags.
// 
// So say CPU requests t be loaded into v, then CPU toggles its flag, and then PPU sees that next cycle and handles the request, 
// and then sets its flag high. Then next cycle PPU doesn't see a request that needs to be handled.
//
// The CPU //toggles// it's flag. It does not care if it is high or low, only that an edge / toggle occurs.
//==============================================================================================================

// logic addr_increment; // 0 is 1, 1 is 32

//======== ASYNC VRAM Register Increment Handling ==========
always_ff @ (posedge CLK) begin
	// Load takes priority over increment
	if (RESET) begin
		ppu_load_vram_handle <= 1'b0;
		ppu_inc_vram_handle <= 1'b0;
		active_vram_address <= 14'd0;
	end
	else begin
		// Load request from CPU
		// Wait until write / read is done before doing handle
		
		// OR, we can latch the address when we send the write request like we do with the data,
		// this sucks though.
		
		// Make sure the write request happens before we increment the address
		if (~(cpu_write_request ^ ppu_write_handle) & ~(cpu_read_request ^ ppu_read_handle)) begin
		
			if (cpu_load_vram_request ^ ppu_load_vram_handle) begin
				active_vram_address <= temp_vram_address;
				ppu_load_vram_handle <= ~ppu_load_vram_handle;
			end
			
			// Increment request from CPU
			else if (cpu_inc_vram_request ^ ppu_inc_vram_handle) begin
				ppu_inc_vram_handle <= ~ppu_inc_vram_handle;
				if (addr_increment) 
					active_vram_address <= active_vram_address + 32;
				else
					active_vram_address <= active_vram_address + 1;
			end
		
		
		
		//TODO: Do we have to increment when we load also here also?? FUCK.
		//
		//
		//
		// logic ppu_hcopy_vram_request;
		// logic ppu_vcopy_vram_request;
		// logic ppu_hinc_vram_request;
		// logic ppu_vinc_vram_request;
		
		
		// TODO: Maybe check if rendering is enabled here also??
		//4 different operation that the PPU can request
			else if (render_enable) begin
				if (ppu_hinc_vram_request) begin
					if (active_vram_address.coarse_x == 31) begin
						active_vram_address.coarse_x <= 0;
						active_vram_address.nametable_x <= ~active_vram_address.nametable_x;
					end
					else begin
						active_vram_address.coarse_x <= active_vram_address.coarse_x + 1;
					end
				end
				// Horizontal Copy Request
				else if (ppu_hcopy_vram_request) begin
					active_vram_address.nametable_x <= temp_vram_address.nametable_x;
					active_vram_address.coarse_x <= temp_vram_address.coarse_x;
				end
				
				if (ppu_vinc_vram_request) begin
					if (active_vram_address.fine_y != 3'b111) begin
						active_vram_address.fine_y <= active_vram_address.fine_y + 1;
					end
					// Fine y should be 7.
					else if (active_vram_address.fine_y == 3'b111) begin
						active_vram_address.fine_y <= 0;
						if (active_vram_address.coarse_y == 29) begin
							active_vram_address.coarse_y <= 0;
							active_vram_address.nametable_y <= ~active_vram_address.nametable_y;
						end else if (active_vram_address.coarse_y == 31) begin
							active_vram_address.coarse_y <= 0;
						end else begin
							active_vram_address.coarse_y <= active_vram_address.coarse_y + 1;
						end
					end
				end
				
				// Vertttical Copy Request
				else if (ppu_vcopy_vram_request) begin
					active_vram_address.fine_y <= temp_vram_address.fine_y;
					active_vram_address.nametable_y <= temp_vram_address.nametable_y;
					active_vram_address.coarse_y <= temp_vram_address.coarse_y;
				end
			end
		end // End read / write handle guard
	end
end



//======== ASYNC PPU Write / Read Handling =======

// ppu_write_request, ppu_read_request, ppu_read_handle, ppu_write_handle, cpu_read_request, cpu_write_request
assign PPU_DATA_OUT = ppu_write_buffer;

always_ff @ (posedge CLK) begin
	if (RESET | ~ENABLE) begin
		PPU_READ <= 1'b0;
		PPU_WRITE <= 1'b0;
		ppu_write_handle <= 1'b0;
		ppu_read_handle <= 1'b0;
		
	end
	else begin
		//TODO: Figure out if we need to handle anything with bus or data or address or just 
		// Reads
		if (cpu_read_request ^ ppu_read_handle) begin
			PPU_READ <= 1'b1;
			ppu_read_handle <= ~ppu_read_handle;
		end
		// TODO: What if we want to clear read? does this work? // These are default values
		else if (ppu_read_request)
			PPU_READ <= 1'b1;
		else 
			PPU_READ <= 1'b0;
		// Writes
		if (cpu_write_request ^ ppu_write_handle) begin
			PPU_WRITE <= 1'b1;
			ppu_write_handle <= ~ppu_write_handle;
		end
		// TODO: What if we want to clear write? does this work? // These are default values
		else if (ppu_write_request)
			PPU_WRITE <= 1'b1;
		else 
			PPU_WRITE <= 1'b0;
	end
end
 
//======== ASYNC NMI Handling  ===================

//ppu_nmi_set_request ppu_nmi_clear_request ppu_nmi_clear_handle cpu_nmi_clear_request

// NMI signals
logic nmi_occured;
assign NMI_n = ~(nmi_generate & nmi_occured); // Unclear if this is active low or not
assign status_vblank = nmi_occured;

always_ff @ (posedge CLK) begin
	if (RESET) begin
		nmi_occured <= 1'b0;
	end
	else begin
		if (cpu_nmi_clear_request ^ ppu_nmi_clear_handle) begin
			ppu_nmi_clear_handle <= ~ppu_nmi_clear_handle;
			nmi_occured <= 1'b0;
		end
		else if (ppu_nmi_set_request)
			nmi_occured <= 1'b1;
		else if (ppu_nmi_clear_request)
			nmi_occured <= 1'b0;
	end
end

//=======================================================
//  Double Linebuffer 
//
//  Lets just do double buffered output as pixel_idx
//	 256 * 2 * 6 = 3072 Bits / LEs for now.
//  This is the itnerface between PPU and VGA controller
//  They don't talk to eachother besides form this
//
//
//  REASONING BEHIND THIS IMPLEMENTATION:
//		Normal NES PPU produces an NTSC signal. NTSC is a signal that has the same VSYNC rate as VGA,
//    BUT has half the HSYNC rate. This means we need to double the HSYNC rate, the way to do this is to 
//    have VGA run twice as fast for each scanline. However we still need to keep VSYNC the same, so we
//    read each scanline twice. This will work out and everyone will be happy.
//
// TODO: FIX WEIRD VERTICAL SCROLLING
//
//
//=======================================================


// Read back from this at twice the speed in 

//=======================================================
//  VGA Controller
//=======================================================

//VGA Clock should be approx 107.5 MHz, / 5x Master.
logic blank_n;

// This depends on our resolution http://tinyvga.com/vga-timing/640x480@60Hz
logic [10:0] drawx, drawy;


vga_controller342 vga_controller (.Clk(VIDEO_CLK), .Reset(RESET), .hs(VGA_HS), .vs(VGA_VS), .blank(blank_n), .DrawX(drawx), .DrawY(drawy));
 
logic [11:0] colors [64] = '{12'h333,12'h014,12'h006,12'h326,12'h403,12'h503,12'h510,12'h420,12'h320,12'h120,12'h031,12'h040,12'h022,12'h000,12'h000,12'h000,
12'h555,12'h036,12'h027,12'h407,12'h507,12'h704,12'h700,12'h630,12'h430,12'h140,12'h040,12'h053,12'h044,12'h000,12'h000,12'h000,
12'h777,12'h357,12'h447,12'h637,12'h707,12'h737,12'h740,12'h750,12'h660,12'h360,12'h070,12'h276,12'h077,12'h000,12'h000,12'h000,
12'h777,12'h567,12'h657,12'h757,12'h747,12'h755,12'h764,12'h772,12'h773,12'h572,12'h473,12'h276,12'h467,12'h000,12'h000,12'h000};


logic [7:0] bingle;
assign bingle = 10'd200;

logic [5:0] pixel_clr_idx;

// This reads back at twice the speed

// Draw x and the PPU are getting out of sync.


// We don't even have to worry about reading the same scanline twice it will just do it for us!
assign pixel_clr_idx = linebuffer[vga_linebuffer][drawx];

always_ff @ (posedge VIDEO_CLK) begin 
	if (blank_n) begin
		if (drawy < 100) begin
			VGA_R <= colors[pixel_clr_idx][11:8] << (1 + bgr_color_emphasis[0]);
			VGA_G <= colors[pixel_clr_idx][7:4] << (1 + bgr_color_emphasis[1]); // Make Brighter TODO: Color Emphasis Bits
			VGA_B <= colors[pixel_clr_idx][3:0] << (1 + bgr_color_emphasis[2]);
		end
		
		else begin
			VGA_R <= colors[pixel_clr_idx][11:8] << (1 + bgr_color_emphasis[0]);
			VGA_G <= colors[pixel_clr_idx][7:4] << (1 + bgr_color_emphasis[1]); // Make Brighter TODO: Color Emphasis Bits
			VGA_B <= colors[pixel_clr_idx][3:0] << (1 + bgr_color_emphasis[2]);
		end
		/**
		else if (drawy < 120) begin
			VGA_R <= OAM[0][0];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 140) begin
			VGA_R <= sprites[0][0];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 160) begin
			VGA_R <= OAM[0][1];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 180) begin
			VGA_R <= OAM[0][2];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 200) begin
			VGA_R <= OAM[0][3];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 220) begin
			VGA_R <= sprites[0][1];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 240) begin
			VGA_R <= sprites[0][2];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end else if (drawy < 260) begin
			VGA_R <= sprites[0][3];
			VGA_G <= 4'b0000;
			VGA_B <= 4'b0000;
		end
		*/
		
	end
	
	else if (~blank_n) begin // Blanking interval
		VGA_R <= 4'b0000;
		VGA_G <= 4'b0000;
		VGA_B <= 4'b0000;
	end
end
	
endmodule