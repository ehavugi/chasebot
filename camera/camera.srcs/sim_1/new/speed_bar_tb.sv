`timescale 1ns / 1ps


// to see the variables inside speed_bar is correct. the output pixel is nothing
module speed_bar_tb;
    logic [10:0] hcount;
    logic [9:0] vcount;
    logic signed [8:0] speed1,speed2;
    logic [11:0] pixel;

    speed_bar uut(.hcount_in(hcount),
                  .vcount_in(vcount),
                  .speed1(speed1), .speed2(speed2),
                  .pixel_out(pixel)
                  );
 initial begin
    vcount = 0;
    hcount = 1;
    speed1 = 9'sd20;
    speed2 = 9'sd50;
    #50
    speed1 = 9'sd100;
    speed2 = -9'sd20;
    #50
    speed1 = -9'sd20;
    speed2 = -9'sd80;
    #50
    $finish;
 end
endmodule
