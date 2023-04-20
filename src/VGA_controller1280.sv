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

// Not Supported Unfortanelyt
module  vga_controller1280 ( input        Clk,       // 50 MHz clock
                                      Reset,     // reset signal
                         output logic hs,        // Horizontal sync pulse.  Active low
								              vs,        // Vertical sync pulse.  Active low
												 
												  blank,     // Blanking interval indicator.  Active low.
												  sync,      // Composite Sync signal.  Active low.  We don't use it in this lab,
												             //   but the video DAC on the DE2 board requires an input for it.
								 output [10:0] DrawX,     // horizontal coordinate
								              DrawY );   // vertical coordinate
	 
    parameter [10:0] hpixels = 11'd1687;
    parameter [10:0] vlines = 11'd1065;
	 
	 
	 // horizontal pixel and vertical line counters
    logic [10:0] hc, vc;
    
	 // signal indicates if ok to display color for a pixel
	 logic display;
	 
    //Disable Composite Sync
    assign sync = 1'b0;
	
	//Runs the horizontal counter  when it resets vertical counter is incremented
   always_ff @ (posedge Clk or posedge Reset )
	begin: counter_proc
		  if ( Reset ) 
			begin 
				 hc <= 11'b00000000000;
				 vc <= 11'b00000000000;
			end
				
		  else 
			 if ( hc == hpixels )  //If hc has reached the end of pixel count
			  begin 
					hc <= 11'b00000000000;
					if ( vc == vlines )   //if vc has reached end of line count
						 vc <= 11'b00000000000;
					else 
						 vc <= (vc + 1);
			  end
			 else 
				  hc <= (hc + 1);  //no statement about vc, implied vc <= vc;
	 end 
   
    assign DrawX = hc;
    assign DrawY = vc;
	 
	 // NEW 
	 //horizontal sync pulse is 112 pixels long at pixels 1328-1440
    //(signal is registered to ensure clean output waveform)
    always_ff @ (posedge Reset or posedge Clk )
    begin : hsync_proc
        if ( Reset ) 
            hs <= 1'b0;
        else  
            if (((hc + 1) >= 11'd1328) & ((hc + 1) < 11'd1440)) 
                hs <= 1'b0;
            else 
				    hs <= 1'b1;
    end
	 
    //vertical sync pulse is 3 lines long at line 1025-1027
    //(signal is registered to ensure clean output waveform)
    always_ff @ (posedge Reset or posedge Clk )
    begin : vsync_proc
        if ( Reset ) 
           vs <= 1'b0;
        else 
            if (((vc + 1) == 11'd1025) | (((vc + 1) == 11'd1026) | ((vc + 1) == 11'd1027)))
			       vs <= 1'b0;
            else 
			       vs <= 1'b1;
    end
       
    //only display pixels between horizontal 0-1599 and vertical 0-1199 (640x480)
    //(This signal is registered within the DAC chip, so we can leave it as pure combinational logic here)    
    always_comb
    begin 
        if ( (hc >= 11'd1280) | (vc >= 11'd1024) ) 
            display = 1'b0;
        else 
            display = 1'b1;
    end 
   
   
    assign blank = display;
	 
    

endmodule
