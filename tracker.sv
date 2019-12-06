`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  MIT 6.111
// Engineer: Emmanuel HAVUGIMANA
// 
// Create Date: 01.12.2019 19:50:24
// Design Name: 
// Module Name: tracker
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


module tracker(
    input clk,
    input use_rgb, 
    input [11:0] cam,
    input [10:0] hcount,
    input [9:0] vcount,
    input [11:0]  goalpixel, 
    input vsync,
    output logic [23:0] radius,
    output logic [31:0] x_center,
    output logic [31:0] y_center,
    output logic [11:0] thres
    );

logic[7:0] h_t,s_t,v_t;

logic [31:0] x_remainder;
logic [31:0] y_remainder;
logic [31:0] x_remainder1;
logic [31:0] y_remainder;
logic clk_65mhz;
logic [31:0] pos_y_d;
logic [31:0] pos_x_d;
logic [31:0] size;
logic [31:0] size_d;
logic [31:0] size_;
logic [31:0] size__;

logic [31:0] pos_y;
logic [31:0] pos_y_;
logic [31:0] pos_x;
logic [31:0] pos_x_;
logic [31:0] pos_x_d;
logic [7:0] h,s,v;
logic [3:0] red,green, blue;
logic [23:0] radius_;
logic [31:0] pos_y_;
logic [26:0] count_f=0;
logic [31:0] square_r;
logic ready4;
logic ready2;
logic ready3;
logic ready1;
logic ready;
logic threshold;

assign size__=size_*3'd7;
assign clk_65mhz=clk;

//changed any pixel from rgb to hsv
rgb2hsv  x(.clock(clk_65mhz),.reset(reset),.r({red,4'h0}), .g({green,4'h0}), .b({blue,4'h0}), .h(h), .s(s), .v(v));

// process goal pixel from rgb to hsv
rgb2hsv  goal_px(.clock(clk_65mhz),.reset(reset),.r({goalpixel[11:8],4'h0}),.g({goalpixel[7:4],4'h0}), .b({goalpixel[3:0],4'h0}), .h(h_t), .s(s_t), .v(v_t));

assign {red,green,blue}=cam; // get camera components


//always @(posedge clk) begin
//    if (count_f<6500000) begin
//        count_f<=count_f+1;
//    end
//    else begin
//        count_f<=0;
//        size_<=size_d;
//        pos_x_<=pos_x_d;
//        pos_y_<=pos_y_d;
//        radius_<=radius;
//    end
//end

always @(negedge vsync) begin
    count_f<=0;
    size_<=size_d;
    pos_x_<=pos_x_d;
    pos_y_<=pos_y_d;
    radius_<=radius;
end

// get the radius given radius squared
sqrt uut (.aclk(clk_65mhz), 
		.s_axis_cartesian_tdata(square_r), 
		.s_axis_cartesian_tvalid(1), 
		.m_axis_dout_tdata(radius),
		.m_axis_dout_tvalid(ready4)
	);

// get  radius squared vien area(size__)
divider32 square_xx(.s_axis_divisor_tdata(32'd22),
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(size__),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({square_r,x_remainder1}),
            .m_axis_dout_tvalid(ready3));
  
// get x_mean given sum of pixels and number of pixels 
divider32 center_xx(.s_axis_divisor_tdata(size_),
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(pos_x_),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({x_center,x_remainder}),
            .m_axis_dout_tvalid(ready2));
 
 // compute Y center given sum of y values of pixels and number of pixels,
 divider32 center_yy(.s_axis_divisor_tdata(size_), 
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(pos_y_),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({y_center,y_remainder}),
            .m_axis_dout_tvalid(ready1));
           

always_comb begin
    if (use_rgb) threshold=(red>(green+4))&&(red>(blue+4));
    else threshold=(h<h_t+5)&&(s>s_t-20)&&(v>v_t-20);
 end
 
always @(posedge clk_65mhz) begin
    if (threshold) begin
        thres<=cam;
        size<=size+1;
        pos_x<=pos_x+hcount;
        pos_y<=pos_y+vcount;
       end
    else begin thres=12'b0;end
    if (vsync) begin 
            size_d<=size;
            pos_x_d<=pos_x;
            pos_y_d<=pos_y;
          end
    else begin size<=0;
        pos_x<=0;
        pos_y<=0;
    end
end

endmodule
