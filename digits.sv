`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2019 09:31:31 PM
// Design Name: 
// Module Name: digits
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module digits(input logic clk,input reset,input halt,input[7:0] points, output reg [27:0] digit);
   // make bins for each ten and count up and in tens

    reg [3:0] tenthsecs=0;
    reg [3:0] seconds=0;
    reg [3:0] tenseconds=0;
    reg [3:0] seconds100=0;
    reg [3:0] seconds1000=0;
    reg [23:0] counter_sec=0;
    

      always_ff @(posedge clk) begin
        digit<={seconds1000,seconds100,tenseconds,seconds,tenthsecs,points};

        if (reset) begin
            counter_sec<=0;
            tenthsecs<=0;
            seconds<=0;
            tenseconds<=0;
            seconds100<=0;
            seconds1000<=0;
            end
       if (halt) counter_sec<=counter_sec;
       else counter_sec<=counter_sec+1;
       if (counter_sec==6500000)begin
        counter_sec<=0;
        tenthsecs<=tenthsecs+1;
       end
       if (tenthsecs==10)
        begin
           tenthsecs<=0;
           seconds<=seconds+1;
         end
         if (seconds>=10)
         begin
           seconds<=0;
           tenseconds<=tenseconds+1;
          end
          if (tenseconds>=10)
                begin
           tenseconds<=0;
           seconds100<=seconds100+1;
          end
     if (seconds100==10)
           begin
            seconds100<=0;
           seconds1000<=seconds1000+1;
          end
      if (seconds1000==10)
          begin
            seconds1000<=0;
          end
   end
endmodule
