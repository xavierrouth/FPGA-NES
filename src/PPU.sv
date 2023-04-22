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
	
	//PPU BUS interface
	input [7:0] PPU_DATA_IN,
	
	output logic [7:0] PPU_DATA_OUT,
	output logic [13:0] PPU_ADDR,
	output logic PPU_WRITE, PPU_READ, // PPU wants to read, ppu want to write
	
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
logic [7:0] vram_addr_latched;

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

logic sprite_render_enable;
logic background_render_enable;
assign background_render_enable = 1'b1;

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

// CPU REQUEST FLAGS
logic cpu_write_request;
logic cpu_read_request;
logic cpu_load_vram_request;
logic cpu_inc_vram_request;
logic cpu_nmi_clear_request;

assign nmi_generate = debug_enable_nmi;
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
	end
	
	//-------------CPU WRITE--------------------------
	else if (CPU_wren) begin // CPU Write
		case (CPU_ADDR)
			// Write Only
			3'h0: begin 
				// Use a struct to make this easier??
				//nmi_generate <= CPU_DATA_IN[7];
				sprite_size <= CPU_DATA_IN[5];
				background_ptable_addr <= CPU_DATA_IN[4]; // 0-> $0000 or 1 -> $1000
				sprite_ptable_addr <= CPU_DATA_IN[3];
				addr_increment <= CPU_DATA_IN[2];
				temp_vram_address.nametable_y <= CPU_DATA_IN[1];
				temp_vram_address.nametable_x <= CPU_DATA_IN[0];
			end
			3'h1: begin
				sprite_render_enable <= CPU_DATA_IN[4];
				//TODO:
				//background_render_enable <= CPU_DATA_IN[3];
			end
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
				CPU_DATA_OUT[5] = ppu_sprite_eval;
			end
			3'h3: ;
			3'h4: ;
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

// VRAM Data Tiles

logic [15:0] ptable_data [2]; // Pattern Table Data
logic [7:0]  atable_data [2]; // Attribute Table Data
logic [7:0]  ntable_byte; // Unclear if this is needed

// OAM
logic [63:0][3:0][7:0] OAM;

// Scanline and Cycle Engine (Very similar to VGA controller)

logic [9:0] cycle, scanline, next_cycle, next_scanline;
logic extra_cycle_latch;
logic extra_cycle;



parameter [9:0] cycle_count = 10'd340; //
parameter [9:0] scanline_count = 10'd261;

logic ppu_vs, ppu_hs;

always @(posedge CLK) begin
	if (RESET) begin
		cycle <= 10'd0;
		scanline <= 10'd0;
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
		scanline <= next_scanline;
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
assign counter = ((cycle - 1) % 8);

// TODO:
// Even / Odd Frames (might fix scrolling issue)

//=======================================================
//  Rendering Logic Always Comb
//=======================================================

// Always_comb for doing stuff

logic [4:0] palette_idx; // idx into some palette
logic [5:0] color_idx; // The color data retrieved from the palette?

always_comb begin
	// ========== Default Values =========================
	
	ppu_nmi_set_request = 1'b0;
	ppu_nmi_clear_request = 1'b0;
	ppu_read_request = 1'b0;
	
	// Weird Register Increments
	ppu_hinc_vram_request = 1'b0;
	ppu_vinc_vram_request = 1'b0;
	ppu_hcopy_vram_request = 1'b0;
	ppu_vcopy_vram_request = 1'b0;
	
	color_idx = 6'b0;
	palette_idx = 5'b0;
	
	PPU_ADDR = active_vram_address[11:0];
	
	if (~render_enable) begin
		PPU_ADDR = active_vram_address;
	end else if (render_enable) begin
		//color_idx = cycle[5:0];
		
		//======== VISIBLE SCANLINES (0-239) ==============
		if (scanline <= 10'd239) begin
			// ----------CYCLES 1-256 and CYCLES 321-338
			if ((cycle >= 1 & cycle < 258) | (cycle >= 321 & cycle < 338)) begin
				// ===========  DO SOME FETCHING HERE  ==============
				case (counter) // Case coutner
					// Fetch nametable byte
					3'd0: begin
						PPU_ADDR = {2'b10, active_vram_address[11:0]};
						ppu_read_request = 1'b1;
					end
					3'd1: begin
						ppu_read_request = 1'b1; // Dumby cycle
					end
					// Fetch attribute table byte
					3'd2: begin
						PPU_ADDR = {2'b10, active_vram_address[11:10], 4'b1111, active_vram_address[9:7], active_vram_address[4:2]};
						ppu_read_request = 1'b1;
					end
					3'd3: ppu_read_request = 1'b1; // Dumby cycle
					// fethc parttern table low 
					3'd4: begin
						PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b0, active_vram_address.fine_y}; //??
						ppu_read_request = 1'b1;
					end
					
					3'd5: ppu_read_request = 1'b1;
					// fetch pattern tile high 
					3'd6: begin
						PPU_ADDR = {1'b0, background_ptable_addr, ntable_byte, 1'b1, active_vram_address.fine_y}; //?? + 8 from pattern table tile low
						ppu_read_request = 1'b1;
					end
					3'd7: begin
						ppu_read_request = 1'b1;
						ppu_hinc_vram_request = 1'b1;
					end
				endcase // End case counter
				
				if (cycle == 10'd256) begin
					// This needs to increment the veritcal position in v, the effective Y scroll coordinate
					ppu_vinc_vram_request = 1'b1;
				end
				
				if (cycle == 257) begin
					// Load shifters
					ppu_hcopy_vram_request = 1'b1;
				end
				
				//================= BACKGROUND PIXEL COMPOSITION=====================
				palette_idx =  5'b0;
				//palette_idx = '{1'b1, atable_data[0][1:0], ptable_data[1][counter], ptable_data[0][counter]};
				if (scanline == 200) begin
					color_idx = 6'h21;
				end else if (cycle == 256) begin
					color_idx = scanline[5:0];
				end else
					color_idx = {ptable_data[1][counter], ptable_data[0][counter]};
				 //'{4'b0010, ptable_data[1][counter], ptable_data[0][counter]};
				 // color_idx = ntable_byte
			end
			// ----------CYCLES 257-320
			if (cycle >= 257 & cycle <= 320) begin
				// Do Sprite Stuff
			end
		end
		//======= POST RENDER SCANLINE (240) ==============
		// Do Nothing
		//======= POST RENDER SCANLINE (241-260) ==============
		if (scanline == 241) begin
			if (cycle == 1) begin
				ppu_nmi_set_request = 1'b1;
			end
		end
		//======== PRE RENDER SCANLINE (261) ==============
		if (scanline == 261) begin 
			if (cycle == 1)
				// End of Vertical Blanking
				ppu_nmi_clear_request = 1'b1;
			else if (cycle >= 280 & cycle <= 304) begin
				// Reload vertical scroll bits TODO: Only if rendering is enabled?
				ppu_vcopy_vram_request = 1'b1;
			end
		end // End Pre Render Scanelin
	end // if rendering_enable
end


//=======================================================
//  Rendering Logic Always FF
//=======================================================

// Always_ff For doing stuff
always_ff @ (posedge CLK) begin
	if (RESET) begin
		ppu_linebuffer <= 1'b0;
		ntable_byte <= 8'd0;
	end else begin // NOT RESET
		if (render_enable) begin
			// TODO: Handle Shifters here:
			// Decided by the composition from earlier.
			// Shift Attribute Table Data To left
			
			// Shift Pattern Table Data 
			linebuffer[ppu_linebuffer][cycle] <= color_idx;
			case (counter)
				// Fetch nametable byte
				3'd0: begin
					// TODO: Load the shiftregs
				end
				3'd1: ntable_byte <= PPU_DATA_IN;
				3'd2: ;
				3'd3: begin
					// TODO: Which atable_data??
					// TODO: Fix this idiot, need to select from 1 of 4 possible 2 bit pairs in the byte
					atable_data[0] <= PPU_DATA_IN;
				end
				// fethc parttern table low 
				3'd4: ;
				3'd5: ptable_data[0] <= PPU_DATA_IN;
				// fetch pattern tile high 
				3'd6: ;
				3'd7: ptable_data[1] <= PPU_DATA_IN;
			endcase
			// Swap linebuffer once a scanline
			if (cycle == 257) begin
				// Do shifters stuff
				;
			end
			if (cycle == 10'd340) begin
				ppu_linebuffer <= ~ppu_linebuffer;
			end
		end // End render enable
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
		
		else if (ppu_hinc_vram_request) begin
			if (active_vram_address.coarse_x == 31) begin
				active_vram_address.coarse_x <= 0;
				active_vram_address.nametable_x <= ~active_vram_address.nametable_x;
			end
			else begin
				active_vram_address.coarse_x <= active_vram_address.coarse_x + 1;
			end
		end
		
		else if (ppu_vinc_vram_request) begin
			if (active_vram_address.fine_y < 7) begin
				active_vram_address.fine_y <= active_vram_address.fine_y + 1;
			end
			// Fine y should be 7.
			else begin
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
		
		// Horizontal Copy Request
		else if (ppu_hcopy_vram_request) begin
			active_vram_address.nametable_x <= temp_vram_address.nametable_x;
			active_vram_address.coarse_x <= temp_vram_address.coarse_x;
		end
		
		// Vertttical Copy Request
		else if (ppu_vcopy_vram_request) begin
			active_vram_address.fine_y <= temp_vram_address.fine_y;
			active_vram_address.nametable_y <= temp_vram_address.nametable_y;
			active_vram_address.coarse_y <= temp_vram_address.coarse_y;
		end
	end
end



//======== ASYNC PPU Write / Read Handling =======

// ppu_write_request, ppu_read_request, ppu_read_handle, ppu_write_handle, cpu_read_request, cpu_write_request

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
		// TODO: What if we want to clear read? does this work?
		else if (ppu_read_request)
			PPU_READ <= 1'b1;
		else 
			PPU_READ <= 1'b0;
		// Writes
		if (cpu_write_request ^ ppu_write_handle) begin
			PPU_WRITE <= 1'b1;
			ppu_write_handle <= ~ppu_write_handle;
		end
		// TODO: What if we want to clear write? does this work?
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
		VGA_R <= colors[pixel_clr_idx][11:8] << 1;
		VGA_G <= colors[pixel_clr_idx][7:4] << 1; // Make Brighter
		VGA_B <= colors[pixel_clr_idx][3:0] << 1;
		
	end
	
	else if (~blank_n) begin // Blanking interval
		VGA_R <= 4'b0000;
		VGA_G <= 4'b0000;
		VGA_B <= 4'b0000;
	end
end
	
endmodule