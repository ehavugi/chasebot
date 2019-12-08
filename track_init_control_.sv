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

module track_init_control(
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
   output[7:0] an,    // Display location 0-7
   output[7:0] jc   //for motor output
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
 parameter DELAY_SIZE=23;
    reg[10:0] hcount_delay  [DELAY_SIZE:0];
    reg [9:0] vcount_delay  [DELAY_SIZE:0];
    reg [11:0] pixel_out_delay [DELAY_SIZE:0];
    reg vsync_delay  [DELAY_SIZE:0];
    reg hsync_delay [DELAY_SIZE:0];
    reg blank_delay [DELAY_SIZE:0];
    reg [4:0] i;
    parameter SEL_D=221;

    always@(posedge clk_65mhz) begin
    //delay the hcount and vcount signals 18 times
    hcount_delay[0]<=hcount;
    vcount_delay[0]<=vcount;
    vsync_delay[0]<=vsync;
    hsync_delay[0]<=hsync;
    blank_delay[0]<=blank;
    pixel_out_delay[0]<=pixel_out;    
    
    
//    pixel_out_delay<=pixel_out;
	for(i=1; i<DELAY_SIZE; i=i+1) begin
		  hcount_delay[i] <= hcount_delay[i-1];
		  vcount_delay[i] <= vcount_delay[i-1];
		  vsync_delay[i] <= vsync_delay[i-1];
		  hsync_delay[i]<=hsync_delay[i-1];
		  blank_delay[i]<=blank_delay[i-1];
		  pixel_out_delay[i]<=pixel_out_delay[i-1];
		  
	    end
    
    end
    
//    xvga xvga1(.vclock_in(clk_65mhz),.hcount_out(hcount_delay[20]),.vcount_out(vcount_delay[20]),
//          .hsync_out(hsync_de\\\\lay[20]),.vsync_out(vsync_delay[20]),.blank_out(blank_delay[20]));

    xvga xvga1(.vclock_in(clk_65mhz),.hcount_out(hcount),.vcount_out(vcount),
          .hsync_out(hsync),.vsync_out(vsync),.blank_out(blank));

    // sw[0] button is user reset
    wire reset;
    debounce db1(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(sw[0]),.clean_out(reset));
    logic scale; //1 when twice scaling 
    
    logic xclk;
    logic[1:0] xclk_count;
          
    logic pclk_buff, pclk_in;
    logic vsync_buff, vsync_in;
    logic href_buff, href_in;
    logic[7:0] pixel_buff, pixel_in;
    
    logic [11:0] cam;
    //logic [3:0] red,green,blue;
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
    
    assign pixel_addr_out = scale?((hcount>>1)+(vcount>>1)*32'd320):hcount+vcount*32'd320;
    assign cam = scale&&((hcount<640) &&  (vcount<480))?frame_buff_out:~scale&&((hcount<320) &&  (vcount<240))?frame_buff_out:12'h000;
    //assign {red,green,blue}=cam;

                                      
   camera_read  my_camera(.p_clock_in(pclk_in),
                          .vsync_in(vsync_in),
                          .href_in(href_in),
                          .p_data_in(pixel_in),
                          .pixel_data_out(output_pixels),
                          .pixel_valid_out(valid_pixel),
                          .frame_done_out(frame_done_out));
   
    
    /////////////////////////////for center positions and hsv/////////////////////////
    logic [23:0] radius;
    logic [31:0] x_center,y_center;
    logic [11:0] thres;
    logic [11:0] pixel_out,goal_pixel,goal_rad;
    logic [7:0] h_t,s_t,v_t;
    logic show_thres,use_rgb;
    logic[3:0] h_cut;
    logic [2:0] v_cut,s_cut;
    rgb2hsv  goal_px(.clock(clk_65mhz),.reset(reset),.r({goal_pixel[11:8],4'h0}),.g({goal_pixel[7:4],4'h0}), .b({goal_pixel[3:0],4'h0}), .h(h_t), .s(s_t), .v(v_t));

    tracker my_tracker(
    .clk(clk_65mhz),
    .rst_in(reset),
    .params({h_cut,s_cut,v_cut}), 
    .cam(cam),
    .hcount(hcount),
    .vcount(vcount),
    .goalpixel(goal_pixel), 
    .vsync(vsync),
    .radius(radius),
    .x_center(x_center),
    .y_center(y_center),
    .thres(thres)
    );
    
    
    
    /////////////INITIALIZE//////////////////
    logic signed [8:0] speed,turn;
    logic en1,ina1,inb1,ina2,inb2,en2;
    logic [7:0] speed_1,speed_2;
    logic signed [8:0] speed1,speed2;
    assign speed1 = {inb1,inb1?~speed_1 + 9'b1:speed_1};
    assign speed2 = {inb2,inb2?~speed_2 + 9'b1:speed_2};
    
    
    logic track,move;
    logic [3:0] direction;
    logic [2:0] state;
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
          .activate_in(sw[1]),
          .sw2(scale), //whether to make the size twice
          .cam(show_thres?thres:cam),
          .cur_pos_x(x_center[8:0]),
          .cur_pos_y(y_center[8:0]),
          .cur_rad(radius),
          .speed1(speed1),
          .speed2(speed2),
          .pixel_out(pixel_out),
          .goal_pixel(goal_pixel),
          .goal_rad(goal_rad),
          .track(track),
          .move(move)
          //for debug
          ,
          .state(state)
//          .cursor_x(cursor_x),
//          .cursor_y(cursor_y),
//          .up(dir[3]), 
//          .down(dir[1]), 
//          .left(dir[2]), 
//          .right(dir[0])
          );
    //////////////////////////////////////////
    
    
    
    /////////////CONTROL//////////////////
    logic [3:0] Kps,Kpt;
    logic [2:0] Kds,Kdt;
    logic [1:0] mode;
    logic [15:0] params;
    logic [8:0] x,y;
    logic [6:0] rad;
    assign params = mode[1]?{Kps,Kds,Kpt,Kdt,mode}:{speed1_in,speed2_in,mode};
    
    assign x = &x_center?9'd160:x_center[8:0];
    assign y = y_center[8:0];
    assign rad = (radius<7'd10)?goal_rad:radius;
    
    control my_control( .clk_in(clk_65mhz),
                        .rst_in(reset),
                        .ready_in(frame_done_out),
                        .cur_pos_x(x),
                        .cur_pos_y(y),
                        .cur_rad(rad),
                        .goal_rad(goal_rad),
                        .params({Kps,Kds,Kpt,Kdt,mode}),
                        .speed(speed),
                        .turn(turn)
                        );
    
    motor_out my_motor( .clk_in(clk_65mhz),
                        .rst_in(reset),
                        .offset(8'd50),
                        .speed_in(speed),
                        .turn_in(turn),
                        .motor_out({en1,ina1,inb1,ina2,inb2,en2}),
                        .speed_1(speed_1),
                        .speed_2(speed_2)
                        );
                        
    assign jc[5:0] = move?{en1,en2,ina2,inb2,ina1,inb1}:6'b0;
    ////////////////////////////////////////////////////////////////
    
    ///////////////switch,segment display FSM/////////////////////////////////////
    parameter INITIALIZE = 0;
    parameter SELECTED = 1;
    parameter CONFIRMED = 2;
    parameter MOVE = 3;
    parameter PAUSE = 4;
    
    logic [1:0] seg_display;
    logic [7:0] speed1_in;  //signed
    logic [7:0] speed2_in;
    
    assign scale = 0;   //no scaling
    //assign mode[1] = 1;
    assign Kps[3] = 0;
    assign Kpt[3] = 0;
    assign speed1_in[1:0] = 0;
    assign speed2_in[1:0] = 0;
    
    // things to display on a 7 segment displays
    always_ff @(posedge clk_65mhz) begin
        case (seg_display)  
            2'b00: data <= {7'b0,speed1,7'b0,speed2};   // xxx(center)xxxx(size)x(switch)
            2'b01: data <= {7'b0,x,3'b0,y, {1'b0,state}};   // display 0123456 + sw[3:0]
            2'b10: data <= {{2'b0,goal_rad},{5'b0,state}}; 
            2'b11: data <= {rad,{1'b0,state}};
            default: data <= {x_center[15:0],y_center[11:0], {1'b0,state}};
        endcase;
     end
     
    
    //switch controls
    //sw[0] is always reset
    //sw[1] is always used for state transition
    
    always @(posedge clk_65mhz) begin
        case(state)
            INITIALIZE: begin
                seg_display <= sw[14:13];
                {h_cut,s_cut,v_cut} = sw[11:2];
                show_thres <= sw[15];
                end
            SELECTED: begin
                seg_display <= sw[14:13];
                {h_cut,s_cut,v_cut} = sw[11:2];
                show_thres <= sw[15];
                
                //calibration related stuff too
                end
            CONFIRMED: begin
                {Kps[2:0],Kds,Kpt[2:0],Kdt,mode} <= sw[15:2];
                speed1_in[7:2] <= sw[15:10];
                speed2_in[7:2] <= sw[9:4];
                end
            PAUSE: begin
                {Kps[2:0],Kds,Kpt[2:0],Kdt,mode} <= sw[15:2];
                speed1_in[7:2] <= sw[15:10];
                speed2_in[7:2] <= sw[9:4];
                end
            default: begin
                {Kps[2:0],Kds,Kpt[2:0],Kdt,mode} <= sw[15:2];
                speed1_in[7:2] <= sw[15:10];
                speed2_in[7:2] <= sw[9:4];
                end
        endcase
    end
    
    
    
    
    
    
    //what to display
    reg b,hs,vs;
    
    always_ff @(posedge clk_65mhz) begin
        hs <= hsync_delay[SEL_D];
        vs <= vsync_delay[SEL_D];
        b <= blank_delay[SEL_D];
        rgb <= pixel_out; // not delay as it  has incurred a delay  already
    end
    
    // the following lines are required for the Nexys4 VGA circuit - do not change
    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

endmodule
