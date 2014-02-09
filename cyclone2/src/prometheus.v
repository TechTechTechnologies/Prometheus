module prometheus
 #( LFSR_DEPTH = 8
  )
  ( clk
  , reset

  , status
  );
  
input  clk;
input  reset;

output status;

reg [23:0] counter = 0;
reg        step    = 1'b0;

wire [LFSR_DEPTH-1 : 0] left_value;
wire [LFSR_DEPTH-1 : 0] right_value;

  assign status = counter[23];

  lfsr 
    #( .DEPTH(LFSR_DEPTH) )
	 left_lfsr
	  ( .clk   (clk)
	  , .reset (reset)
	  , .dir   (1'b0)
	  , .step  (step)
	  , .taps  (8'hB8)
	  , .value (left_value)
	  );
	  
  lfsr 
    #( .DEPTH(LFSR_DEPTH) )
	 right_lfsr
	  ( .clk   (clk)
	  , .reset (reset)
	  , .dir   (1'b1)
	  , .step  (step)
	  , .taps  (8'hB8)
	  , .value (right_value)
	  );
	  
	wm8731_codec
	  #( .BITDEPTH (LFSR_DEPTH) )
	  audio
	   ( .clk       (clk)
		, .reset     (reset)
		
      , .left_in   (left_value)
      , .right_in  (right_value)
		);

  always @(posedge clk)
  begin
    if (reset == 1'b0)
	 begin
	   counter <= 0;
		step    <= 1'b0;
	 end else
	 begin
      if (counter == 24'hFFFFFF)
      begin
        counter <= 0;
		  step    <= 1'b1;
      end else
      begin
        counter <= counter + 1'b1;
		  step    <= 1'b0;
      end
	 end
  end

endmodule

