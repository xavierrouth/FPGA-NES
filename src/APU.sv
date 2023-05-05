//=======================================================
//  APU
//  - This module represents the APU (Audio Procesing Unit) of the NES architecture.
//
//  - CPU BUS Section [$4000 - $4017] 
//  
//  Pulse Channels:
//  $400(0/4): Timer
//  $400(1/5): Length Counter
//  $400(2/6): Envelope 
//  $400(3/7): Sweep
//
//======================================================

//
// Note this whole thing should not be written as behaviorally as it is.
// With the amount of reuse of modules that we see aswell as async resets,
// we could really do with writing it using SystemVerilog modules much more.
// This would be an interesting contrast i feel to the style PPU is written in.
//

module APU (
	
	input 	MCLK,    // This is the 21.5 MHz NES master CLK
	input    CPU_CLK, // This is just the 1.79 MHz CPU CLK
	
	// Audio Interface Clocks
	input 	LRCLK,
	input 	SCLK,
	
	input    RESET,
	
	// CPU BUS interface
	input [7:0] CPU_DATA_IN,
	input [4:0] CPU_ADDR,
	
	input CPU_wren, CPU_rden, // CPU wants to read / CPU wants to write
	
	output logic [7:0] CPU_DATA_OUT,
	
	output logic frame_irq,
	
	
	output logic    DOUT // Serial Sample Data Out
);

//=======================================================
//  Status / Frame Counter Interface
//=======================================================

//Status:

// Status Writes (Channel Enables / Inputs):
logic pulse_enable [2];
logic noise_enable;
logic triangle_enable;
logic dmc_enable; // We aren;t actualyl using this

// Status Reads (Outptus):
logic dmc_interrupt;
logic frame_interrupt;
logic dmc_active;

// Frame Counter:
logic frame_counter_mode;
logic frame_counter_mode_update;

logic frame_irq_inhibit;

logic frame_interrupt_clear_request;

assign frame_irq = (frame_interrupt & (~frame_irq_inhibit));
assign dmc_active = 1'b0;


always_ff @ (posedge CPU_CLK) begin
	if (RESET) begin
		pulse_enable <= '{default:'0};
		noise_enable <= 1'b0;
		triangle_enable <= 1'b0;
		dmc_interrupt <= 1'b0;
		frame_counter_mode_update <= 1'b0;
		frame_interrupt_clear_request <= 1'b0;
	end
	
	if (CPU_ADDR == 5'h15) begin
		// CPU Write
		if (CPU_wren) begin
			pulse_enable[0] <= CPU_DATA_IN[0];
			pulse_enable[1] <= CPU_DATA_IN[1];
			triangle_enable <= CPU_DATA_IN[2];
			noise_enable <= CPU_DATA_IN[3];
			
			dmc_interrupt <= 1'b0;
		end
		// CPU Read
		else if (CPU_rden) begin
			frame_interrupt_clear_request <= ~frame_interrupt_clear_request;
			; // This is in always_comb lol
		end
	end
	
	else if (CPU_ADDR == 5'h17) begin
		if (CPU_wren) begin
			frame_irq_inhibit <= CPU_DATA_IN[6];
			
			frame_counter_mode <= CPU_DATA_IN[7];
			frame_counter_mode_update <= ~frame_counter_mode_update;
			if (CPU_DATA_IN[6])
				frame_interrupt_clear_request <= ~frame_interrupt_clear_request;
				
		end
	end
end 

// Always Comb to do the same thing
always_comb begin

	// Default Value:
	CPU_DATA_OUT = 8'h00;
	
	if (CPU_ADDR == 5'h15) begin
		// CPU Write
		if (CPU_wren) begin
			// Signals to clear length coutners.
			; // No jk
		end
		// CPU Read
		else if (CPU_rden) begin
			CPU_DATA_OUT[7] = dmc_interrupt;
			CPU_DATA_OUT[6] = frame_irq;
			CPU_DATA_OUT[4] = dmc_active; 
			CPU_DATA_OUT[3] = 1'b0; // (noise_length_counter > 0);
			CPU_DATA_OUT[2] = 1'b0; // (triangle_length_counter > 0);
			CPU_DATA_OUT[1] = (pulse_length_counter[1] > 0);
			CPU_DATA_OUT[0] = (pulse_length_counter[0] > 0);
			
		end
	end
end

//=======================================================
//  Frame Sequencer 
//=======================================================
// frame_counter_mode & frame_irq_inhibit
// (ticks approximately 4 times per frame (240Hz) and executes either a 4 or 5 step sequence.
// Need to derive a clock that runs at 240 Hz, 

logic APU_CLK;

// Divide CPU_CLK by two
always_ff @ (posedge CPU_CLK) begin
	if (~RESET)
		APU_CLK <= ~APU_CLK;
	else
		APU_CLK <= 1'b0;
end

logic [14:0] apu_clk_counter;
logic quarter_clock;
logic half_clock;

logic frame_interrupt_set_request;

// Frame Sequencer
APU_FRAME_SEQUENCER frame_sequencer(.cpu_clk(CPU_CLK), .reset(RESET), .mode(frame_counter_mode), .mode_udpate(frame_counter_mode_update), 
												.half_clock(half_clock), .quarter_clock(quarter_clock), .frame_irq_request(frame_interrupt_set_request)); 

// Frame Interrupt Request Handler:

logic frame_interrupt_clear_handle;
logic frame_interrupt_set_handle;

always_ff @ (posedge CPU_CLK) begin
	if (RESET) begin
		frame_interrupt <= 1'b0;
	end 
	else begin
		if (frame_interrupt_clear_request ^ frame_interrupt_clear_handle) begin
			frame_interrupt_clear_handle <= ~frame_interrupt_clear_handle;
			frame_interrupt <= 1'b0;
		end
		else if (frame_interrupt_set_request ^ frame_interrupt_set_handle) begin
			frame_interrupt_set_handle <= ~frame_interrupt_set_handle;
			if (frame_irq_inhibit)
				frame_interrupt <= 1'b0;
			else
				frame_interrupt <= 1'b1;
		end
		else 
			frame_interrupt <= frame_interrupt;
	end
end

//=======================================================
//  Pulse Channels
//=======================================================

// Two of each because two pulse channels

// Parameters Set By CPU:

// $4000:
logic [1:0] pulse_duty [2];
logic 		pulse_loop_flag [2]; // High = Infinite Play, 0 = One Shot
logic 		pulse_constant_volume [2]; // 1 = Constant Volume, 0 = envelope.
logic [3:0]	pulse_volume [2];

// $4001:
logic 	   sweep_enable [2];
logic [2:0] sweep_period [2];
logic 		sweep_negate [2];
logic [2:0] sweep_shift  [2];

// $4002 / 3:
logic [10:0] pulse_timer [2];
logic [4:0]  pulse_lc_input [2];


//=================== CPU I/O for Pulse Channels ======================

always_ff @ (posedge CPU_CLK) begin // This will handle reads / writes from CPU 	
	if (RESET) begin
		pulse_duty <= '{default:'0};
		pulse_loop_flag <= '{default:'0};
		pulse_constant_volume <= '{default:'0};
		pulse_volume <= '{default:'0};
		sweep_enable <= '{default:'0};
		sweep_period <= '{default:'0};
		sweep_negate <= '{default:'0};
		sweep_shift <= '{default:'0};
		pulse_timer <= '{default:'0};
		pulse_lc_input <= '{default:'0};
	end
	
	// Write to a Pulse Channel
	if (CPU_ADDR < 5'h08) begin 
		if (CPU_wren) begin // CPU Write
			case (CPU_ADDR[2:0])
				// Pulse Channel 0
				3'h00: begin
					pulse_duty[0] <= CPU_DATA_IN[7:6];
					pulse_loop_flag[0] <= CPU_DATA_IN[5];
					pulse_constant_volume[0] <= CPU_DATA_IN[4];
					pulse_volume[0] <= CPU_DATA_IN[3:0];
					
					// Duty cycle is changed, but sequencers current position isn't affected
				end
				3'h01: begin
					; // Don't care for now tbhers
				end
				3'h02: begin
					pulse_timer[0][7:0] <= CPU_DATA_IN;
				end
				3'h03: begin
					pulse_timer[0][10:8] <= CPU_DATA_IN[2:0];
					
					// Handled in always_comb
					// The sequencer is immediately restarted at the first value of the current sequence.
					// The envelope is also restarted.
					// The divider period is not reset.
				end	
				// Pulse Channel 1
				3'h04: begin
					pulse_duty[1] <= CPU_DATA_IN[7:6];
					pulse_loop_flag[1] <= CPU_DATA_IN[5];
					pulse_constant_volume[1] <= CPU_DATA_IN[4];
					pulse_volume[1] <= CPU_DATA_IN[3:0];
					// Duty cycle is changed, but sequencers current position isn't affected
				end
				3'h05: begin
					; // Don't care for now tbhers
				end
				3'h06: begin
					pulse_timer[1][7:0] <= CPU_DATA_IN;
				end
				3'h07: begin
					pulse_timer[1][10:8] <= CPU_DATA_IN[2:0];
					
					// Handled in always_comb
					// The sequencer is immediately restarted at the first value of the current sequence.
					// The envelope is also restarted.
					// The divider period is not reset.
				end
			endcase
		end
		// No Reads
	end
end


logic pulse_sequencer_restart [2];
logic pulse_envelope_restart [2];
logic pulse_lc_load [2];
logic pulse_timer_reload[2];

always_comb begin
	pulse_sequencer_restart[0] = 1'b0;
	pulse_envelope_restart[0] = 1'b0;
	
	pulse_sequencer_restart[1] = 1'b0;
	pulse_envelope_restart[1] = 1'b0;
	
	pulse_lc_load[0] = 1'b0;
	pulse_lc_load[1] = 1'b0;
	
	pulse_sweep_reload[0] = 1'b0;
	pulse_sweep_reload[1] = 1'b0;
	
	pulse_timer_reload[0] = 1'b0;
	pulse_timer_reload[1] = 1'b0;
	
	if (CPU_ADDR < 5'h08) begin 
		// TODO: Does writing to timer registers instantly load the current_period??
		if (CPU_wren) begin // CPU Write
			if (CPU_ADDR[2:0] == 3'h01) begin
				pulse_sweep_reload[0] = 1'b1;
			end
			if (CPU_ADDR[2:0] == 3'h05) begin
				pulse_sweep_reload[0] = 1'b1;
			end
			if (CPU_ADDR[2:0] == 3'h02) begin
				pulse_timer_reload[0] = 1'b1;
			end
			if (CPU_ADDR[2:0] == 3'h06) begin
				pulse_timer_reload[1] = 1'b1;
			end
			if (CPU_ADDR[2:0] == 3'h03) begin
				pulse_sequencer_restart[0] = 1'b1;
				pulse_lc_load[0] = 1'b1;
				pulse_timer_reload[0] = 1'b1;
			end
			if (CPU_ADDR[2:0] == 3'h07) begin
				pulse_sequencer_restart[1] = 1'b1;
				pulse_lc_load[1] = 1'b1;
				pulse_timer_reload[1] = 1'b1;
			end
			
		end
	end
end



//=================== ENVELOPE GENERATOR ======================
logic [3:0] pulse_envelope_out [2];


// TODO: Start flag, tie it low so it always starts dfo rnwo.
APU_ENVELOPE_GENERATOR pulse_one_envelope (.cpu_clk(CPU_CLK), .clk_edge(quarter_clock), .reset(pulse_envelope_restart[0]), .loop(pulse_loop_flag[0]), 
														 .start(1'b0), .constant_volume(pulse_constant_volume[0]), .volume(pulse_volume[0]), 
														 .envelope_out(pulse_envelope_out[0]));

APU_ENVELOPE_GENERATOR pulse_two_envelope (.cpu_clk(CPU_CLK), .clk_edge(quarter_clock), .reset(pulse_envelope_restart[1]), .loop(pulse_loop_flag[1]), 
														 .start(1'b0), .constant_volume(pulse_constant_volume[1]), .volume(pulse_volume[1]), 
														 .envelope_out(pulse_envelope_out[1]));

//=================== SWEEP / TIMERUNITS =============================

logic pulse_sequencer_clock [2];
logic pulse_timer_mute[2];
logic pulse_sweep_reload[2];

	
APU_SWEEP_TIMER_UNIT pulse_one_timer (.cpu_clk(CPU_CLK), .clk(APU_CLK), .clk_edge(half_clock), .reset(RESET), .sweep_reload(pulse_sweep_reload[0]), 
												  .timer(pulse_timer[0]), .sequencer_clock(pulse_sequencer_clock[0]), .timer_reload(pulse_timer_reload[0]),
												  .mute(pulse_timer_mute[0]), .sweep_enable(sweep_enable[0]), .sweep_period(sweep_period[0]), .sweep_negate(sweep_negate[0]),
												  .sweep_shift(sweep_shift[0]));
												  
APU_SWEEP_TIMER_UNIT pulse_two_timer (.cpu_clk(CPU_CLK), .clk(APU_CLK), .clk_edge(half_clock), .reset(RESET), .sweep_reload(pulse_sweep_reload[1]), 
												  .timer(pulse_timer[1]), .sequencer_clock(pulse_sequencer_clock[1]), .timer_reload(pulse_timer_reload[1]),
												  .mute(pulse_timer_mute[1]), .sweep_enable(sweep_enable[1]), .sweep_period(sweep_period[1]), .sweep_negate(sweep_negate[1]),
												  .sweep_shift(sweep_shift[1]));

//=================== PULSE SEQUENCER =========================
	
// Variables That Change during Pringlehead oeprations:
logic pulse_sequencer_waveform [2];

APU_PULSE_SEQUENCER pulse_one_sequencer (.cpu_clk(CPU_CLK), .clk_edge(pulse_sequencer_clock[0]), .reset(pulse_sequencer_restart[0]), .duty(2'b00), 
													  .waveform(pulse_sequencer_waveform[0]));

APU_PULSE_SEQUENCER pulse_two_sequencer (.cpu_clk(CPU_CLK), .clk_edge(pulse_sequencer_clock[1]), .reset(pulse_sequencer_restart[1]), .duty(2'b00), 
													  .waveform(pulse_sequencer_waveform[1]));

//=================== LENGTH COUNTERS =========================
// Length Counter Look Up Table:

logic [7:0] pulse_length_counter [2]; // These are the outputs of the length counters

APU_LENGTH_COUNTER pulse_one_lc (.cpu_clk(CPU_CLK), .clk_edge(half_clock), .load(pulse_lc_load[0]), .halt(pulse_loop_flag[0]), .enable(pulse_enable[0]), 
											.data_in(CPU_DATA_IN[7:3]), .counter_out(pulse_length_counter[0]));
											
APU_LENGTH_COUNTER pulse_two_lc (.cpu_clk(CPU_CLK), .clk_edge(half_clock), .load(pulse_lc_load[1]), .halt(pulse_loop_flag[1]), .enable(pulse_enable[1]), 
											.data_in(CPU_DATA_IN[7:3]), .counter_out(pulse_length_counter[1])); 

// ================== PULSE OUTPUTS / MIXER INPUTS =============

logic [3:0] pulse_mixer_in [2];

always_comb begin
	// The Mixer receives the pulse channel's current evelope volume
	
	// EXCEPT when
	// The sequencers output is zero, or
	// the fverflow from the sweep unit's adder is silencing the channel, or
	// the length counter is zero, or
	// the timer has  avalue less than eight.
	
	// TOOD: Sweep?
	
	// Channel 1
	if ((pulse_sequencer_waveform[0] == 0) | (pulse_length_counter[0] == 0) | pulse_timer_mute[0])
		pulse_mixer_in[0] = 4'h0;
	else
		pulse_mixer_in[0] = pulse_envelope_out[0];
	
	// Channel 2
	if ((pulse_sequencer_waveform[1] == 0) | (pulse_length_counter[1] == 0) | pulse_timer_mute[1])
		pulse_mixer_in[1] = 4'h0;
	else
		pulse_mixer_in[1] = pulse_envelope_out[1];

end

//=======================================================
//  Triangle Channel 
//=======================================================

/**
// $4000:
logic [1:0] triangle_duty;
logic 		triangle_loop_flag; // High = Infinite Play, 0 = One Shot
logic 		triangle_constant_volume; // 1 = Constant Volume, 0 = envelope.
logic [3:0]	triangle_volume;


// $4002 / 3:
logic [10:0] triangle_timer;
logic [4:0]  triangle_lc_input;

//=================== ENVELOPE GENERATOR ======================
logic [3:0] triangle_envelope_out;

// Channel 1
always_ff @ (posedge quarter_clock or posedge pulse_envelope_restart[0]) begin
	; // TODO:
end

// Channel 2
always_ff @ (posedge quarter_clock or posedge pulse_envelope_restart[1]) begin
	; // TODO:
end

assign triangle_envelope_out = triangle_volume;


//=================== SWEEP / TIMERUNITS =============================

logic triangle_sequencer_clock;
logic triangle_timer_gate_disable;

APU_SWEEP_TIMER_UNIT triangle_timer (.cpu_clk(CPU_CLK), .clk(APU_CLK), .reset(1'b0), .timer(triangle_timer), .sequencer_clock(triangle_sequencer_clock), 
												  .timer_gate_disable(triangle_timer_gate_disable));

//=================== PULSE SEQUENCER =========================
	
// Variables That Change during Pringlehead oeprations:
logic triangle_sequencer_waveform;

APU_TRIANGLE_SEQUENCER triangle_sequencer (.cpu_clk(CPU_CLK), .clk_edge(triangle_sequencer_clock), .reset(triangle_sequencer_restart), .duty(2'b00), 
													  .waveform(triangle_sequencer_waveform));

//=================== LENGTH COUNTERS =========================
// Length Counter Look Up Table:

logic [7:0] triangle_length_counter; // These are the outputs of the length counters

APU_LENGTH_COUNTER triangle_lc (.cpu_clk(CPU_CLK), .clk_edge(half_clock), .load(triangle_lc_load), .halt(triangle_loop_flag), .enable(triangle_enable), 
											.data_in(CPU_DATA_IN[7:3]), .counter_out(triangle_length_counter));
											
*/								
//=======================================================
//  Noise Channel 
//=======================================================



//=======================================================
//  MIXER 
//=======================================================
 
logic [23:0] square_out;

logic [23:0] sample;

always_comb begin
	square_out = (pulse_mixer_in[0] + pulse_mixer_in[1]) << 12; // rshift 7 to divide then lshift 2 to amplfiy
	sample = square_out; // Some constant volume amplification could be used here i suppose?
end

//=======================================================
//  Audio Controller
//		At this point,  we should just provide *sample* with whatever we want to play.
//    The sample reg is how we interface with this thing, that is the only output the 
//    NES side of the APU should see. Then this logic processes it into a serial signal
//    in a format that the sgtl audio thingy expects.
//
//=======================================================

logic [31:0] long;

always_ff @(posedge LRCLK or posedge SCLK) begin
	if (LRCLK)
		long <= {1'b0, sample, 7'b0}; // Load a new sample
	else
		long <= {long[30:0], 1'b0}; // Left Shift
end

assign DOUT = long[31];


endmodule