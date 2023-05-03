//-------------------------------------------------------------------------
//      VGA controller                                                   --
//      Kyle Kloepper                                                    --
//      4-05-2005                                                        --
//                                                                       --
//      Modified by Stephen Kempf 04-08-2005                             --
//                                10-05-2006                             --
//                                03-12-2007                             --
//      Translated by Joe Meng    07-07-2013                             --
//      Fall 2014 Distribution                                           --
//                                                                       --
//      Used standard 640x480 vga found at epanorama                     --
//                                                                       --
//      reference: http://www.xilinx.com/bvdocs/userguides/ug130.pdf     --
//                 http://www.epanorama.net/documents/pc/vga_timing.html --
//                                                                       --
//      note: The standard is changed slightly because of 25 mhz instead --
//            of 25.175 mhz pixel clock. Refresh rate drops slightly.    --
//                                                                       --
//      For use with ECE 385 Lab 7 and Final Project                     --
//      ECE Department @ UIUC                                            --
//-------------------------------------------------------------------------


module  vga_controller342 ( input     Clk,       // 10.7 MHz clock
                                      Reset,     // reset signal
                         output logic hs,        // Horizontal sync pulse.  Active low
								              vs,        // Vertical sync pulse.  Active low 
												  blank,     // Blanking interval indicator.  Active low.
												  sync,      // Composite Sync signal.  Active low.  We don't use it in this lab,
												             //   but the video DAC on the DE2 board requires an input for it.
								 output [10:0] DrawX,     // horizontal coordinate
								              DrawY );   // vertical coordinate
    
	// 800 horizontal pixels indexed 0 to 799
	// 525 vertical pixels indexed 0 to 524
	
	// Horizontal sync start + end
	parameter [10:0] h_sb = 11'd280;//11'd656;
	parameter [10:0] h_se = 11'd321;//11'd752;

	parameter [10:0] v_sb = 11'd490;
	parameter [10:0] v_se = 11'd491;
	
	
	// These need fixing?
	parameter [10:0] h_tot = 11'd340;// 11'd341; //11'd800;
	parameter [10:0] v_tot = 11'd523; // What happens if we do this? // This changes scrolling you should fix it

	parameter [10:0] h_active = 11'd255; //11'd640
	parameter [10:0] v_active = 11'd480;

	logic h_pol = 1'b1;
	logic v_pol = 1'b1;


	// signal indicates if ok to display color for a pixel
	logic display;
	
	/**
	always @(posedge Clk)
	begin
	if (Reset)
		  middleclk <= 1'b0;
	else
		  middleclk <= ~middleclk;	
	end
	*/
	
	logic dclk, middleclk;
	
	assign dclk = Clk;
	
	/**
	always @(posedge middleclk)
	begin
	if (Reset)
		  dclk <= 1'b0;
	else
		  dclk <= ~dclk;	
	end
	*/


	

	logic [11:0] nexth, nextv, hcount, vcount;
	
	assign DrawX = hcount;
	assign DrawY = vcount;
	
   always @(posedge dclk) begin
   if (Reset)
     begin
        nexth <= 11'h0;
        nextv <= v_tot - 11'd1;
        hcount <= 11'h0;
        vcount <= v_tot - 11'd1;
        vs <= 1'b0;
        hs <= 1'b0;
     end
   else
     begin
        if (nexth == h_tot)
          nexth <= 11'h000;
        else
          nexth <= nexth + 1'b1;

        if (nexth == h_tot)
          if (nextv == v_tot)
            nextv <= 11'h000;
          else
            nextv <= nextv + 1'b1;

        hcount <= nexth;
        vcount <= nextv;

        hs <= h_pol ^ ((hcount < h_sb) | (hcount >= h_se));
        vs <= v_pol ^ ((vcount < v_sb) | (vcount >= v_se));
		  blank <= ((hcount < h_active) & (vcount < v_active));
     end // else: !if(Reset)  
	end
    

endmodule