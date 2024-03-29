`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2019 05:42:29 PM
// Design Name: 
// Module Name: track_init
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Updated 8/10/2019 Lab 3
// Updated 8/12/2018 V2.lab5c
// Create Date: 10/1/2015 V1.0
// Design Name:
// Module Name: labkit
//
//////////////////////////////////////////////////////////////////////////////////

module track_init(
   input clk_100mhz,
   input[15:0] sw,
   input btnc, btnu, btnl, btnr, btnd,
   input [7:0] ja,
   input [2:0] jb,
   output   jbclk,
   input [2:0] jd,
   output   jdclk,
   output[3:0] vga_r,
   output[3:0] vga_b,
   output[3:0] vga_g,
   output vga_hs,
   output vga_vs,
   output led16_b, led16_g, led16_r,
   output led17_b, led17_g, led17_r,
   output[15:0] led,
   output ca, cb, cc, cd, ce, cf, cg, dp,  // segments a-g, dp
   output[7:0] an    // Display location 0-7
   );
    logic clk_65mhz;
    // create 65mhz system clock, happens to match 1024 x 768 XVGA timing
    clk_wiz_lab3 clkdivider(.clk_in1(clk_100mhz), .clk_out1(clk_65mhz));

    logic [31:0] data;      //  instantiate 7-segment display; display (8) 4-bit hex
    wire [6:0] segments;
    assign {cg, cf, ce, cd, cc, cb, ca} = segments[6:0];
    display_8hex display(.clk_in(clk_65mhz),.data_in(data), .seg_out(segments), .strobe_out(an));
    assign  dp = 1'b1;  // turn off the period

    assign led = sw;  
    
    wire [10:0] hcount;    // pixel on current line
    wire [9:0] vcount;     // line number
    wire hsync, vsync, blank;
    wire [11:0] pixel;
    reg [11:0] rgb;    
    xvga xvga1(.vclock_in(clk_65mhz),.hcount_out(hcount),.vcount_out(vcount),
          .hsync_out(hsync),.vsync_out(vsync),.blank_out(blank));


    // sw[0] button is user reset
    wire reset;
    debounce db1(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(sw[0]),.clean_out(reset));
   
    logic xclk;
    logic[1:0] xclk_count;
    
    /////////////////////////////for center positions and hsv/////////////////////////
    logic ready2;
    logic ready;
    logic [31:0] x_mean;
    logic [31:0] y_mean;
    logic [31:0] x_remainder;
    logic [31:0] y_remainder;
    logic [31:0] pos_y_d;
    logic [31:0] pos_x_d;
    logic [31:0] size;
    logic [31:0] size_d;
    logic [31:0] size_;
    logic [31:0] pos_x;
    logic [31:0] pos_x_;
    logic [31:0] pos_y;
    logic [31:0] pos_y_;
    logic [31:0] pos_x;
    logic [31:0] pos_x_d;
    logic [7:0] h,s,v;
    logic [3:0] red,green, blue;
    logic[11:0] thres;
    logic [23:0] radius_;
    logic [31:0] square_r;
    logic [31:0] x_remainder1;
    logic [31:0] y_remainder;
    logic [23:0] radius;
    logic ready3;
    logic ready4;
    logic ready_y;


    rgb2hsv  x(.clock(clk_65mhz),.reset(reset),.r({red,4'h0}), .g({green,4'h0}), .b({blue,4'h0}), .h(h), .s(s), .v(v));

// things to display on a 7 segment displays
always_ff @(posedge clk_65mhz) begin
    case (sw[14:13])  
        2'b00:  data <= {pos_x_d[27:0], sw[3:0]};   // xxx(center)xxxx(size)x(switch)
        2'b01:  data <= {y_mean[15:0],x_mean[11:0], sw[3:0]};   // display 0123456 + sw[3:0]
        2'b10: data <= {size_[27:0], sw[3:0]}; 
        2'b11: data <= {radius,sw[3:0]}; 
    endcase;
 end
          
    logic pclk_buff, pclk_in;
    logic vsync_buff, vsync_in;
    logic href_buff, href_in;
    logic[7:0] pixel_buff, pixel_in;
    
    logic [11:0] cam;
    logic [11:0] frame_buff_out;
    logic [15:0] output_pixels;     //pixel from camera             
    logic [12:0] processed_pixels;  //stored inside bram
    logic valid_pixel;  //1 if inside camera frame
    logic frame_done_out;   //pulse indicating the end of frame
    
    logic [16:0] pixel_addr_in;
    logic [16:0] pixel_addr_out;
    
    assign xclk = (xclk_count >2'b01);
    assign jbclk = xclk;
    assign jdclk = xclk;
    
    
    blk_mem_gen_0 jojos_bram(.addra(pixel_addr_in), 
                             .clka(pclk_in),
                             .dina(processed_pixels),
                             .wea(valid_pixel),
                             .addrb(pixel_addr_out),
                             .clkb(clk_65mhz),
                             .doutb(frame_buff_out));
    
    always_ff @(posedge pclk_in)begin
        if (frame_done_out)begin
            pixel_addr_in <= 17'b0;  
        end else if (valid_pixel)begin
            pixel_addr_in <= pixel_addr_in +1;  
        end
    end
    
    always_ff @(posedge clk_65mhz) begin
        pclk_buff <= jb[0];//WAS JB
        vsync_buff <= jb[1]; //WAS JB
        href_buff <= jb[2]; //WAS JB
        pixel_buff <= ja;
        pclk_in <= pclk_buff;
        vsync_in <= vsync_buff;
        href_in <= href_buff;
        pixel_in <= pixel_buff;
        xclk_count <= xclk_count + 2'b01;
        processed_pixels = {output_pixels[15:12],output_pixels[10:7],output_pixels[4:1]};
            
    end
    
    assign pixel_addr_out = sw[2]?((hcount>>1)+(vcount>>1)*32'd320):hcount+vcount*32'd320;
    assign cam = sw[2]&&((hcount<640) &&  (vcount<480))?frame_buff_out:~sw[2]&&((hcount<320) &&  (vcount<240))?frame_buff_out:12'h000;
    assign {red,green,blue}=cam;



//sampling for displaying
//*TODO change this to a vsync clock??*//
logic [26:0] count_f=0;
always @(posedge clk_65mhz) begin
    if (count_f<6500000) begin
        count_f<=count_f+1;
    end
    else begin
        count_f<=0;
        size_<=size_d;
        pos_x_<=pos_x_d;
        pos_y_<=pos_y_d;
        radius_<=radius;
    end
    
end

sqrt uut (.aclk(clk_65mhz), 
		.s_axis_cartesian_tdata(size_), 
		.s_axis_cartesian_tvalid(1), 
		.m_axis_dout_tdata(radius),
		.m_axis_dout_tvalid(ready4)
	);
//logic size__=
divider32 square_xx(.s_axis_divisor_tdata(size_*7),
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(32'd22),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({square_r,x_remainder1}),
            .m_axis_dout_tvalid(ready3));
  
divider32 center_xx(.s_axis_divisor_tdata(size_),
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(pos_x_),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({x_mean,x_remainder}),
            .m_axis_dout_tvalid(ready2));
 
 divider32 center_yy(.s_axis_divisor_tdata(size_),
            .s_axis_divisor_tvalid(1),
            .s_axis_dividend_tdata(pos_y_),
            .s_axis_dividend_tvalid(1),
            .aclk(clk_65mhz),
            .m_axis_dout_tdata({y_mean,y_remainder}),
            .m_axis_dout_tvalid(ready_y));
  
            
logic recount;
logic threshold;
always_comb begin
    if (sw[12]) threshold=(red>(green+4))&&(red>(blue+4));
    else threshold=(h<40)&&(s>100);
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
                                        
   camera_read  my_camera(.p_clock_in(pclk_in),
                          .vsync_in(vsync_in),
                          .href_in(href_in),
                          .p_data_in(pixel_in),
                          .pixel_data_out(output_pixels),
                          .pixel_valid_out(valid_pixel),
                          .frame_done_out(frame_done_out));
   
    
    
    /////////////INITIALIZE//////////////////
    logic signed [8:0] speed,turn;
    logic en1,ina1,inb1,ina2,inb2,en2;
    logic [7:0] speed_1,speed_2;
    logic signed [8:0] speed1,speed2;
    assign speed1 = {inb1,inb1?~speed_1 + 9'b1:speed_1};
    assign speed2 = {inb2,inb2?~speed_2 + 9'b1:speed_2};
    
    logic [11:0] pixel_out,goal_pixel,goal_rad;
    logic track,mode;
    logic [3:0] direction;
    assign direction = {btnu,btnd,btnl,btnr};
    
    initialize initializer(
          .clk_65mhz(clk_65mhz),
          .reset(reset),
          .hcount(hcount),
          .vcount(vcount),
          //.vsync(vsync_in),
          .vsync(frame_done_out),
          .directions(direction), //up,down,left,right
          .confirm_in(btnc),
          .activate_in(sw[3]),
          .sw2(sw[2]), //whether to make the size twice
          .cam(sw[15]?thres:cam),
          .cur_pos_x(x_mean[8:0]),
          .cur_pos_y(y_mean[8:0]),
          .cur_rad(radius>>1),
          .speed1(speed1),
          .speed2(speed2),
          .pixel_out(pixel_out),
          .goal_pixel(goal_pixel),
          .goal_rad(goal_rad),
          .track(track),
          .move(move)
          //for debug
//          ,
//          .state(state),
//          .cursor_x(cursor_x),
//          .cursor_y(cursor_y),
//          .up(dir[3]), 
//          .down(dir[1]), 
//          .left(dir[2]), 
//          .right(dir[0])
          );
    //////////////////////////////////////////
    
    
    
    /////////////CONTROL//////////////////
    control my_control( .clk_in(clk_65mhz),
                        .rst_in(reset),
                        .ready_in(frame_done_out),
                        .cur_pos_x(x_mean[8:0]),
                        .cur_pos_y(y_mean[8:0]),
                        .cur_rad(radius>>1),
                        .goal_rad(7'd30),
                        .params({{2'b00,sw[11:10]},3'b000,{2'b00,sw[9:8]},3'b000,1'b1,sw[7]}),
                        .speed(speed),
                        .turn(turn)
                        );
    
    motor_out my_motor( .clk_in(clk_65mhz),
                        .rst_in(reset),
                        .speed_in(speed),
                        .turn_in(turn),
                        .motor_out({en1,ina1,inb1,ina2,inb2,en2}),
                        
                        .speed_1(speed_1),
                        .speed_2(speed_2)
                        );
    
    //what to display
    wire up,down;
    reg b,hs,vs;
    
    always_ff @(posedge clk_65mhz) begin
        hs <= hsync;
        vs <= vsync;
        b <= blank;
        rgb <= pixel_out;
    end
    
    // the following lines are required for the Nexys4 VGA circuit - do not change
    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

endmodule


module synchronize #(parameter NSYNC = 3)  // number of sync flops.  must be >= 2
                   (input clk,in,
                    output reg out);

  reg [NSYNC-2:0] sync;

  always_ff @ (posedge clk)
  begin
    {out,sync} <= {sync[NSYNC-2:0],in};
  end
endmodule

///////////////////////////////////////////////////////////////////////////////
//
// Pushbutton Debounce Module (video version - 24 bits)  
//
///////////////////////////////////////////////////////////////////////////////

module debounce (input reset_in, clock_in, noisy_in,
                 output reg clean_out);

   reg [19:0] count;
   reg new_input;

//   always_ff @(posedge clock_in)
//     if (reset_in) begin new <= noisy_in; clean_out <= noisy_in; count <= 0; end
//     else if (noisy_in != new) begin new <= noisy_in; count <= 0; end
//     else if (count == 650000) clean_out <= new;
//     else count <= count+1;

   always_ff @(posedge clock_in)
     if (reset_in) begin 
        new_input <= noisy_in; 
        clean_out <= noisy_in; 
        count <= 0; end
     else if (noisy_in != new_input) begin new_input<=noisy_in; count <= 0; end
     else if (count == 650000) clean_out <= new_input;
     else count <= count+1;


endmodule

//////////////////////////////////////////////////////////////////////////////////
// Engineer:   g.p.hom
// 
// Create Date:    18:18:59 04/21/2013 
// Module Name:    display_8hex 
// Description:  Display 8 hex numbers on 7 segment display
//
//////////////////////////////////////////////////////////////////////////////////

module display_8hex(
    input clk_in,                 // system clock
    input [31:0] data_in,         // 8 hex numbers, msb first
    output reg [6:0] seg_out,     // seven segment display output
    output reg [7:0] strobe_out   // digit strobe
    );

    localparam bits = 13;
     
    reg [bits:0] counter = 0;  // clear on power up
     
    wire [6:0] segments[15:0]; // 16 7 bit memorys
    assign segments[0]  = 7'b100_0000;  // inverted logic
    assign segments[1]  = 7'b111_1001;  // gfedcba
    assign segments[2]  = 7'b010_0100;
    assign segments[3]  = 7'b011_0000;
    assign segments[4]  = 7'b001_1001;
    assign segments[5]  = 7'b001_0010;
    assign segments[6]  = 7'b000_0010;
    assign segments[7]  = 7'b111_1000;
    assign segments[8]  = 7'b000_0000;
    assign segments[9]  = 7'b001_1000;
    assign segments[10] = 7'b000_1000;
    assign segments[11] = 7'b000_0011;
    assign segments[12] = 7'b010_0111;
    assign segments[13] = 7'b010_0001;
    assign segments[14] = 7'b000_0110;
    assign segments[15] = 7'b000_1110;
     
    always_ff @(posedge clk_in) begin
      // Here I am using a counter and select 3 bits which provides
      // a reasonable refresh rate starting the left most digit
      // and moving left.
      counter <= counter + 1;
      case (counter[bits:bits-2])
          3'b000: begin  // use the MSB 4 bits
                  seg_out <= segments[data_in[31:28]];
                  strobe_out <= 8'b0111_1111 ;
                 end

          3'b001: begin
                  seg_out <= segments[data_in[27:24]];
                  strobe_out <= 8'b1011_1111 ;
                 end

          3'b010: begin
                   seg_out <= segments[data_in[23:20]];
                   strobe_out <= 8'b1101_1111 ;
                  end
          3'b011: begin
                  seg_out <= segments[data_in[19:16]];
                  strobe_out <= 8'b1110_1111;        
                 end
          3'b100: begin
                  seg_out <= segments[data_in[15:12]];
                  strobe_out <= 8'b1111_0111;
                 end

          3'b101: begin
                  seg_out <= segments[data_in[11:8]];
                  strobe_out <= 8'b1111_1011;
                 end

          3'b110: begin
                   seg_out <= segments[data_in[7:4]];
                   strobe_out <= 8'b1111_1101;
                  end
          3'b111: begin
                  seg_out <= segments[data_in[3:0]];
                  strobe_out <= 8'b1111_1110;
                 end
       endcase
      end
endmodule

