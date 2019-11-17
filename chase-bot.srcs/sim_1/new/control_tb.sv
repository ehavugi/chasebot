`timescale 1ns / 1ps


module control_tb();
logic clk;
logic rst;
logic ready;
logic [8:0] cur_pos_x;
logic [8:0] cur_pos_y;
logic [8:0] cur_rad;
logic [8:0] goal_rad;
logic [15:0] params;
logic signed [8:0] speed;
logic signed [8:0] turn;

control test(.clk_in(clk), .rst_in(rst), .ready_in(ready), .cur_pos_x(cur_pos_x), .cur_pos_y(cur_pos_y), .cur_rad(cur_rad),
                .goal_rad(goal_rad), .params(params), .speed(speed), .turn(turn));

always begin
    clk = !clk;
    ready = !ready;
    #5;
end

initial begin
clk = 0;
rst = 0;
ready = 0;
cur_pos_x = 0;
cur_pos_y = 0;
cur_rad = 0;
goal_rad = 0;
params = 0;
#10;
rst = 1;
#10
goal_rad = 9'd50;
cur_pos_x = 9'


end
endmodule
