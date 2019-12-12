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
    input rst_in,
    input [9:0] params, 
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
logic [7:0] h,s,v;
logic [3:0] red,green, blue;
logic [23:0] radius_;
logic [26:0] count_f=0;
logic [31:0] square_r;
logic ready4;
logic ready2;
logic ready3;
logic ready1;
logic ready;
logic threshold;

logic [4:0] h1,h2;

logic[3:0] h_cut_in;
logic [2:0] s_cut_in,v_cut_in;
logic [7:0] h1_cut;
logic [7:0] h2_cut;
logic [5:0] s_cut,v_cut;
logic [7:0] h_low,h_high,v_low,s_low;


//thresholding
//assign {h_cut_in,s_cut_in,v_cut_in} = params;
assign {h1,h2} = params;

assign h1_cut = h1 * 3'd3;
assign h2_cut=h2*3'd3;
assign s_cut = s_cut_in * 3'd5;
assign v_cut = v_cut_in * 3'd5;

assign h_low = (h_t > h1_cut)?h_t - h1_cut:0;
assign s_low = (s_t > 20)?s_t - 20:0;
assign v_low = (v_t > 20)?v_t - 20:0;
assign h_high = (h_t < 8'hff- h2_cut)?h_t + h2_cut:8'hff;
logic   [2:0] cls;
color_class color_xx(.h(h_t),.s(s_t),.v(v_t),.cls(cls) );

always_comb begin
    if (cls==1)
         threshold=(h<h_t+3)&&(s>v_low)&&(v>v_low);
   else if(cls==2)
         threshold=(h>8'd20)&&(h<=8'd30)&&(s>s_low)&&(v>v_low);
    else if (cls==3) 
          threshold=((h>8'd3)&&(h<8'd10)&&(s>8'd100)&&(v>8'd100));
   else
      threshold=((h<=h_t+5)&& (h>h_t-5) &&(s>8'd100)&&( v>8'd100));
  end

//assign threshold=(h<h_high)&&(s>s_low)&&(v>v_low);

//thresholding end

assign size__=size_*3'd7;
assign clk_65mhz=clk;

//changed any pixel from rgb to hsv
rgb2hsv  x(.clock(clk_65mhz),.reset(rst_in),.r({red,4'h0}), .g({green,4'h0}), .b({blue,4'h0}), .h(h), .s(s), .v(v));

// process goal pixel from rgb to hsv
rgb2hsv  goal_px(.clock(clk_65mhz),.reset(rst_in),.r({goalpixel[11:8],4'h0}),.g({goalpixel[7:4],4'h0}), .b({goalpixel[3:0],4'h0}), .h(h_t), .s(s_t), .v(v_t));

assign {red,green,blue}=cam; // get camera components


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
           

//always_comb begin
//     threshold=(h<h_t+5)&&(s>s_t-20)&&(v>v_t-20);
// end


 
    parameter DELAY_SIZE=23;
    reg[10:0] hcount_delay  [DELAY_SIZE:0];
    reg [9:0] vcount_delay  [DELAY_SIZE:0];
    reg vsync_delay  [DELAY_SIZE:0];
    reg [4:0] i;
    parameter SEL_D=22;

    always@(posedge clk_65mhz) begin
    //delay the hcount and vcount signals 18 times
    hcount_delay[0]<=hcount;
    vcount_delay[0]<=vcount;
    vsync_delay[0]<=vsync;
    
    
//    pixel_out_delay<=pixel_out;
	for(i=1; i<DELAY_SIZE; i=i+1) begin
		  hcount_delay[i] <= hcount_delay[i-1];
		  vcount_delay[i] <= vcount_delay[i-1];
		  vsync_delay[i] <= vsync_delay[i-1];  
	    end    
    end
    
always @(posedge clk_65mhz) begin
    if (threshold) begin
        thres<=cam;
        size<=size+1;
        pos_x<=pos_x+hcount_delay[SEL_D]; // to use the right values of hcount and vcoun given delay of rgb2hsv
        pos_y<=pos_y+vcount_delay[SEL_D];
       end
    else begin thres=12'b0;end
    if (vsync_delay[SEL_D]) begin 
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
