`timescale 1ns / 1ps
module rgb2hsv_tb;
    logic clock;
    logic reset;
    logic[7:0] r,g,b,h,s,v;

     rgb2hsv  x(.clock(clock),.reset(reset),.r(r), .g(g), .b(b), .h(h), .s(s), .v(v));
    always begin
        #5;
        clock = !clock;
     end

     initial begin
        clock = 0;
        reset = 0;
        #50
        reset = 1;
        #10;
        reset = 0;
        r = 8'h00;
        g=8'h00;
        b=8'h00;
        #400;
        reset = 1;
        #10;
        reset = 0;
        #10;
        b = 8'hff;
        g=8'h00;
        #400;
        #10;
        #500;  //as you run it...should see 10101010 show up ont eh data out line
     end
endmodule