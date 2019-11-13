`timescale 1ns / 1ps


module motor_out_tb();

logic clk;
logic rst;
logic signed [8:0] speed;
logic signed [6:0] turn;
logic [5:0] motor_out;

motor_out test(.clk_in(clk),
                .rst_in(rst),
                .speed_in(speed),
                .turn_in(turn),
                .motor_out(motor_out)    //en1,ina1,inb1,ina2,inb2,en2
    );
    
    
always begin
    clk = !clk;
    #5;
end


initial begin
clk = 0;
rst = 0;
speed = 0;
turn = 0;
#10;
rst = 1;
#10
rst = 0;
#10
speed = 9'sd10;
#100000
turn = 7'sd50;
#100000
speed =  -9'sd230;
#100000
turn = -7'sd15;
#100000
$finish;

end
endmodule
