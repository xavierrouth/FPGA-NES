//
//This module represents the state machine setup for our PPU rendering.
//
//
//
//
//
//		Has two shift registers, one 16 bit with 8 top bit parallel load. Second is 8 bit 
//		with 1 bit load to top bit. Included is a synch reset, load_en, shift_en, load, clk
//
//		State machine has four states to determine which part of the rendering process the current
//		frame is on. There are 262 scanlines per frame, each scanline takes 341 clock cycles(use PPU clock)
//		Four states: Pre_Render (261) : dummy scanline, fills shift registers with first 2 tiles data -- still don't know why scanline varies in length
//		Visible_Render (0-239) : Each visible scanline here. Has internal state machine depending on
//								 which clock cycle it is currently on (0-340) More info here: https://www.nesdev.org/wiki/PPU_rendering
//		Post_Render (240) : PPU idles during this scanline
//		VBlank_Render (241-260) : VBlank flag is set high on second tick of scanline 241. PPU makes no 
//		memory accesses here so PPU memory can be accessed by program
//
//
//
module shift_reg_16 ( input clk,
					  input reset,
					  input shift_en,
					  input load_en,
					  input [7:0] load,
					  output [7:0] data
);

logic [15:0] registers;

always_ff (posedge clk) begin

if(reset)
registers <= 16'd0;

if(load_en & !reset & !shift_en)
registers [15:8] <= load;

if(shift_en & !reset & !load_en)
registers [15:0] <= {registers[15], registers[15:1]};

if(shift_en & load_en & !reset)begin
registers [7:0] <= registers[8:1];
registers [15:8] <= load;
end
end

always_comb begin
data = registers[7:0];
end

endmodule

module shift_reg_8 ( input clk,
					 input reset,
					 input shift_en,
					 input load_en,
					 input load,
					 output [7:0] data		 
					 );
logic [7:0] registers;

always_ff (posedge clk) begin
if(reset)
registers <= 8'd0;
if(load_en & !reset & !shift_en)
registers[7] <= load;
if(shift_en & !reset & !load)
registers[7:0] <= {registers[7], registers[7:1]};
if(shift_en & load_en & !reset)begin
registers[6:0] <= registers[7:1];
registers[7] <= load;
end
end

always_comb begin
	data = reg;
end
endmodule



//STATE MACHINE START HERE

logic PPU_clk, PPU_reset, load_en, shift_en;
logic [7:0] upper_load, lower_load, upper_data, lower_data;

shift_reg_16 upper_reg_16 (.clk(PPU_clk), .reset(PPU_reset), .shift_en(shift_en), .load_en(load_en), .load(upper_load), .data(upper_data));
shift_reg_16 lower_reg_16 (.clk(PPU_clk), .reset(PPU_reset), .shift_en(shift_en), .load_en(load_en), .load(lower_load), .data(lower_data));

logic pal_upper_load, pal_lower_load, pal_shift_en, pal_load_en;
logic [7:0] pal_upper_data, pal_lower_data;

shift_reg_8 pal_upper_reg_8 (.clk(PPU_clk), .reset(PPU_reset), .shift_en(pal_shift_en), .load_en(pal_load_en), .load(pal_upper_load), .data(pal_upper_data));
shift_reg_8 pal_lower_reg_8 (.clk(PPU_clk), .reset(PPU_reset), .shift_en(pal_shift_en), .load_en(pal_load_en), .load(pal_lower_load), .data(pal_lower_data));


//create mux using fine_x as selector. Need to add sprite priority later
logic [2:0] fine_x;

logic [1:0] pixel_data, palette_data;

logic nametable_fetch, attribute_fetch, pattern_low_fetch, pattern_high_fetch;
logic rendering, reset, mem_fetch_en, VBlank; //determines if rendering is on or off, reset, if PPU can fetch memory, and VBlank
enum logic [3:0] {Pre_Render,
				  Visible_Render,
				  Post_Render,
				  VBlank_Render } curr_state, next_state;

logic [8:0] cycle_count, next_cycle_count;
logic [8:0] scanline_count, next_scanline_count;

always_ff (posedge clk) begin

if(reset) begin
curr_state <= Pre_Render;
cycle_count <= 9'd0;
scanline_count <= 9'd0;
end
else begin
curr_state <= next_state;
cycle_count <= next_cycle_count;
scanline_count <= next_scanline_count;
end

end

always_comb begin

unique case (curr_state)
Pre_Render:
begin
	if(cycle_count = 340) begin
	next_state = Visible_Render;
	next_cycle_count = 9'd0;
	next_scanline_count = 0;
	end
	else begin
	next_state = Pre_Render;
	next_cycle_count = cycle_count + 1;
	next_scanline_count = scanline_count;
	end
end

Visible_Render:
begin
	if(cycle_count = 340) begin  //at the end of a scanline
		if(scanline_count = 239) begin  //at last scanline of visible scanlines
			next_scanline_count = scanline_count +1;
			next_state = Post_Render;
			next_cycle_count = 9'd0;
		end
		else begin
			next_scanline_count = scanline_count + 1;
			next_state = Visible_Render;
			next_cycle_count = 9'd0;
		end
	end
	else begin
		next_state = Visible_Render;
		next_scanline_count = scanline_count;
		next_cycle_count = cycle_count + 1;
	end
end

Post_Render:
begin
	if(cycle_count = 340) begin
		next_scanline_count = scanline_count + 1;
		next_state = VBlank_Render;
		next_cycle_count = 9'd0;
	end
	next_scanline_count = scanline_count;
	next_state = Post_Render;
	next_cycle_count = cycle_count + 1;
end

VBlank_Render:
begin
	if(cycle_count = 340) begin
		if(scanline_count = 260) begin
			next_scanline_count = scanline_count + 1;
			next_state = Pre_Render;
			next_cycle_count = 9'd0;
		end
		else begin
			next_scanline_count = scanline_count + 1;
			next_state = VBlank_Render;
			next_cycle_count = 9'd0;
		end
	end
	else begin
		next_scanline_count = scanline_count;
		next_state = VBlank_Render;
		next_cycle_count = cycle_count + 1;
	end
end

default : begin
	next_state = curr_state;
	next_scanline_count = 261; //Pre_Render
	next_cycle_count = 9'd0;
end
endcase

//start of output calculation:

//default------------------------------------

VBlank = 0;
nametable_fetch = 0;
attribute_fetch = 0;
pattern_low_fetch = 0;
pattern_high_fetch = 0;

//default------------------------------------


case (curr_state)

Pre_Render: begin
	if(rendering) begin

	end
end

Visible_Render: begin
	if(rendering) begin
		if(cycle = 0)
		//do nothing
		if(cycle > 0 && cycle < 257) begin
			if(cycle[2:0] = 1 | cycle[2:0] = 2)begin
				nametable_fetch = 1;
			end
			if(cycle[2:0] = 3 | cycle[2:0]=4) begin
				attribute_fetch = 1;
			end
			if(cycle[2:0] = 5 | cycle[2:0]=6) begin
				pattern_low_fetch = 1;
			end
			if(cycle[2:0] = 7 | cycle[2:0]=0) begin
				pattern_high_fetch = 1;
			end

			if(cycle > 0 && cycle[2:0] = 0) begin
				load_en = 1;
				pal_load_en = 1;
			end


		end
		if(cycle > 256 && cycle < 321) begin
			//sprite stuff
		end
		if(cycle > 320 && cycle < 337) begin
			if(cycle[2:0] = 0 | cycle[2:0] = 1)begin
				nametable_fetch = 1;
			end
			if(cycle[2:0] = 2 | cycle[2:0]=3) begin
				attribute_fetch = 1;
			end
			if(cycle[2:0] = 4 | cycle[2:0]=5) begin
				pattern_low_fetch = 1;
			end
			if(cycle[2:0] = 6 | cycle[2:0]=7) begin
				pattern_high_fetch = 1;
			end

			if(cycle[2:0] = 7) begin
				load_en = 1;
				pal_load_en = 1;
			end
		end
		if(cycle > 336)
		nametable_fetch = 1;
		
	end
end

Post_Render: begin 
	if(rendering) begin

	end
end

VBlank_Render: begin
	if(rendering) begin
		if(scanline = 241 & cycle_count > 0)
		VBlank = 1;
		if(scanline > 241)
		VBlank = 1;
	end
end

default : ;

endcase


end