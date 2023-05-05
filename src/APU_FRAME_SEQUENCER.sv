//=======================================================
//  APU_FRAME_SEQUENCER
//  - This module represents the frame sequencer.
//  - The sequecner keeps track of how many APU cycles have elapsed in total, 
//    and each step of the sequence will occur once that ttotal has reached the individual ammount, 
//  
//=======================================================


module APU_FRAME_SEQUENCER(
	input cpu_clk,
	
	input mode, 
	input mode_udpate,
	
	input reset,
	
	output half_clock,
	output quarter_clock,
	
	output frame_irq_request
);

logic [15:0] counter;
logic mode_handler;

// Frame Sequencer
always_ff @ (posedge cpu_clk) begin
	if (reset) begin
		counter <= 16'b0;
	end
	else begin
		if ((mode_handler ^ mode_udpate) && mode == 1'b1) begin
			mode_handler <= ~mode_handler;
			half_clock <= ~half_clock;
			quarter_clock <= ~quarter_clock;
		end
		else begin
			// MODE ZERO
			if (~mode) begin
				if (counter == 7457) begin
					quarter_clock <= ~quarter_clock;
					counter <= counter + 1;
				end
				else if (counter == 14913) begin
					quarter_clock <= ~quarter_clock;
					half_clock <= ~half_clock;
					counter <= counter + 1;
				end
				else if (counter == 22371) begin
					quarter_clock <= ~quarter_clock;
					counter <= counter + 1;
				end
				else if (counter >= 29839) begin
					counter <= 0;
					quarter_clock <= ~quarter_clock;
					half_clock <= ~half_clock;
					frame_irq_request <= ~frame_irq_request;
				end else
					counter <= counter + 1;
			end
			
			// MODE ONE
			else if (mode) begin
				if (counter == 7457) begin
					quarter_clock <= ~quarter_clock;
					counter <= counter + 1;
				end
				else if (counter == 14913) begin
					quarter_clock <= ~quarter_clock;
					half_clock <= ~half_clock;
					counter <= counter + 1;
				end
				else if (counter == 22371) begin
					quarter_clock <= ~quarter_clock;
					counter <= counter + 1;
				end
				else if (counter >= 37281) begin
					counter <= 0;
					quarter_clock <= ~quarter_clock;
					half_clock <= ~half_clock;
				end else
					counter <= counter + 1;
			end
		end
	end
end



endmodule