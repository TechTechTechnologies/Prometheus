interface serdes
 #( parameter BIDIRECTIONAL = 1'b0
  , parameter OUTGOING      = 1'b0 
  , parameter BITDEPTH      = 8
  )
  ( clk
  , reset

  , sigclk
  , enable
  , data_outgoing
  , data_incoming
  );

generate
  if (BIDIRECTIONAL == 1'b1)
  begin:GENERATE_BIDIRECTIONAL_SERDES
  end else
  begin
    if (OUTGOING == 1'b1)
    begin:GENERATE_OUTGOING_SERDES
    end else
    begin:GENERATE_INCOMING_SERDES
    end
  end
endgenerate

endinterface
