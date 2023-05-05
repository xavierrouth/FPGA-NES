//=======================================================
//  APU_SWEEP_TIMER_UNIT
//  - Sweeps a pringle for the pulsesr
//  - This is the same as the timer
//  
//=======================================================

module APU_SWEEP_TIMER_UNIT(
	input cpu_clk,
	input clk, // Apu Clock
	
	input clk_edge,
	
	input reset,
	
	input timer_reload,
	input sweep_reload,
	
	input [10:0] timer,
	
	// Sweep Unit Inputs
	input 	   sweep_enable,
	input [2:0] sweep_period, 
	input 		sweep_negate, 
	input [2:0] sweep_shift,
	
	output sequencer_clock,
	output mute
);


//=================== SWEEP UNIT =========================
logic clk_handle;
logic [11:0] target_period;
logic [10:0] current_period;

logic [10:0] current_period_final;

logic [10:0] divider_counter;
logic [2:0] divider_period;

logic reset_flag;

logic timer_reload_delayed;

assign divider_period = sweep_period;

always_comb begin
	// Continously calculate target period
	if(sweep_negate)
		target_period = current_period - (timer >> sweep_shift);
	else
		target_period = current_period + (timer >> sweep_shift);
end

always_ff @ (posedge cpu_clk) begin
	if (reset) begin
		current_period <= 0; //?? 
	end
	else begin
	
		// Weird Handles
		if(timer_reload) begin
			timer_reload_delayed <= 1'b1;
		end
		if (timer_reload_delayed) begin
			current_period <= timer;
			timer_reload_delayed <= 1'b1;
		end
		
		if(sweep_reload) begin
			reset_flag <= 1'b1; 
		end
		
		// On Quarter Clock Edge
		else if (clk_handle ^ clk_edge) begin
			clk_handle <= ~clk_handle;
			// Clock Divider
			if (reset_flag) begin
				divider_counter <= divider_period;
				reset_flag <= 1'b0;
			end
			if (divider_counter == 0) begin
				divider_counter <= divider_period;
				
				if (sweep_enable && (sweep_shift != 0) && ~mute) begin
					current_period <= target_period;
				end
			end
			else
				divider_counter <= divider_counter - 1;
			
		end
	end
end


//=================== TIMER UNIT =========================

assign current_period_final = timer;

logic [11:0] counter;

always_ff @ (posedge cpu_clk) begin
	if (reset) begin
		counter <= 12'b0;
	end
	else begin
		if ((counter >> 1) == current_period_final) begin
			sequencer_clock <= ~sequencer_clock;
			counter <= 0;
		end
		else
			counter <= counter + 1;
	end
end

always_comb begin
	
	mute = 1'b0;
	
	if (current_period_final < 8) // | target_period > 11'h7FF)
		mute = 1'b1;

end

endmodule