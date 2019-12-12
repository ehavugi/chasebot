`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2019 02:46:49 PM
// Design Name: 
// Module Name: color_class
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


module color_class(
        input [7:0] h,
        input [7:0] s,
        input [7:0] v,
        output reg [2:0] cls );
 always_comb begin
     if ((h<=8'd3) &&(s>8'd50)&&(v>8'd50)) cls=3'b001;
     else if ((h>8'd3)&&(h<8'd10)&&(s>8'd100)&&(v>8'd100)) cls=3'b100;
     else begin
        if ((h<=8'd32)&& (h>8'd20) &&(s>8'd100)&&( v>8'd100)) cls=3'b010; // yellow
     else begin
        if ((h<=8'd32) &&(s>8'd100)&&( v>8'd100)) cls=3'b011;
      else cls=3'b111;
     end
    end
end
 
endmodule
