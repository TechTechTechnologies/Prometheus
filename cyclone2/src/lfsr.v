module lfsr
 #( parameter DEPTH = 8
  )
  ( clk
  , reset

  , dir
  , taps
  , step
  , value    
  );

input  clk;
input  reset;

input                dir;
input  [DEPTH-1 : 0] taps;
input                step;
output [DEPTH-1 : 0] value;

wire                 next;
reg    [DEPTH-1 : 0] bits = ~0;

  assign next  = ^ (value & taps);
  assign value = bits;
  
  always @(posedge clk)
  begin
    if (reset == 1'b0)
    begin
      bits <= ~0;
    end else
    begin
      if (step == 1'b1)
      begin
        if (dir == 1'b0)
        begin
          bits <= {next, bits[DEPTH-1 : 1]};
        end else
        begin 
          bits <= {bits[DEPTH-2 : 0], next};
        end
      end else
      begin
        bits <= bits;
      end
    end
  end
 
endmodule

