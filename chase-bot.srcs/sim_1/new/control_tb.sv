`timescale 1ns / 1ps


module control_tb();
logic clk;
logic rst;
logic ready;
logic [8:0] cur_pos_x;
logic [8:0] cur_pos_y;
logic [8:0] cur_rad;
logic [6:0] goal_rad;
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
rst = 0;
#10
params = 16'b0011_001_0011_001_10;
goal_rad = 7'd25;
cur_pos_y = 9'd120;
#10
//standard
cur_pos_x = 9'd160;
cur_rad = 7'd25;
#100
cur_pos_x = 9'd180;
cur_rad = 7'd20;
#100
cur_pos_x = 9'd170;
cur_rad = 7'd23;
#100
cur_pos_x = 9'd190;
cur_rad = 7'd30;
#100
cur_pos_x = 9'd140;
cur_rad = 7'd23;
#100
cur_pos_x = 9'd130;
cur_rad = 7'd28;
#100
//check threshold
cur_pos_x = 9'd300;
cur_rad = 7'd25;
#100
cur_pos_x = 9'd10;
cur_rad = 7'd25;
#100
cur_pos_x = 9'd160;
cur_rad = 7'd25;
#100
$finish;
end
endmodule
