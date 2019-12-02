`timescale 1ns / 1ps
module divider_tb;
    logic clock;
    logic reset;
    logic[7:0] r,g,b,h,s,v;

    divider1  hue_div1(
    .clk(clock),
    .sign(0),
    .start(start),
    .dividend(s_top),
    .divider(s_buttom),
    .remainder(s_quotient),
    .ready(s_rfd));    
    
     always begin
        #5;
        clock = !clock;
     end

     initial begin
        clock = 0;
        #50
        reset = 1;
        #10;
        r = 8'hff;
       g=8'h00;

        b = 8'h00;
        #50;  //as you run it...should see 10101010 show up ont eh data out line
     end
endmodule