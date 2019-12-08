
`timescale 1ns / 1ps
//
//
module param(input logic clk,
               input logic[5:7] sel_in,
                 input logic[15:8] value_in,
                 input logic program_,
                 output logic[7:0] value_out,
                 output logic[2:0] sel_out,
                 output logic programmed);
                 
   always_ff @(posedge clk) begin
   if (program_) begin
       sel_out<=sel_in;
       value_out<=value_in;
       programmed<=1'b1;
   end
   end
                 
    
endmodule

