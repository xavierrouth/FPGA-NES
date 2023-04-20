module COLOR_PALETTE (
	input CLK,
	input RESET,
	
	input [5:0] index,
	
	
	// Video Output
	output   [ 3: 0]   VGA_R,
	output   [ 3: 0]   VGA_G,
	output   [ 3: 0]   VGA_B
);

// Given a 6 bit index return RGB color combo

// lets just do this with regs for now

// [3:0] red [3:0] green [3:0] blue = [11:0]

// This is just 800 regs / LEs who cares hopefully won't take long to route

logic [11:0] colors [64] = '{12'h333,12'h014,12'h006,12'h326,12'h403,12'h503,12'h510,12'h420,12'h320,12'h120,12'h031,12'h040,12'h022,12'h000,12'h000,12'h000,
12'h555,12'h036,12'h027,12'h407,12'h507,12'h704,12'h700,12'h630,12'h430,12'h140,12'h040,12'h053,12'h044,12'h000,12'h000,12'h000,
12'h777,12'h357,12'h447,12'h637,12'h707,12'h737,12'h740,12'h750,12'h660,12'h360,12'h070,12'h276,12'h077,12'h000,12'h000,12'h000,
12'h777,12'h567,12'h657,12'h757,12'h747,12'h755,12'h764,12'h772,12'h773,12'h572,12'h473,12'h276,12'h467,12'h000,12'h000,12'h000};// Index into via index 


always_comb begin
	VGA_R = colors[index][11:8];
	VGA_G = colors[index][7:4];
	VGA_B = colors[index][3:0];
end

endmodule