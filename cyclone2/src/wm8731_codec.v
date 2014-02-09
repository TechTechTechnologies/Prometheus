module wm8731_codec
 #( parameter BITDEPTH = 16
  )
  ( clk
  , reset

  , wr_rate
  , rate

  , wr_gain
  , gain

  , wr_data
  , left_in
  , right_in

  , left_out
  , right_out
  );

`include wm8731.h

input  clk;
input  reset;

input        wr_rate;
input  [3:0] rate;

input        wr_gain;
input  [5:0] gain;

input                   wr_data;
input  [BITDEPTH-1 : 0] left_in;
input  [BITDEPTH-1 : 0] right_in;

output [BITDEPTH-1 : 0] left_out;
output [BITDEPTH-1 : 0] right_out;

enum reg [1:0]
{
  IDLE,
  WR_REG,
  RUNNING
} state = IDLE;
 

  always @(posedge clk)
  begin
    if (reset == 1'b0)
    begin
      state <= IDLE;
    end else 
    begin
      case (state)
        IDLE:
        begin
        end
        WR_REG:
        begin
        end
        RUNNING:
        begin
        end
        default:
        begin
        end
      endcase
    end
  end

endmodule

