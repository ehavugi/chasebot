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
    assign {red,green,blue}=cam;

                                      
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
    
    rgb2hsv  goal_px(.clock(clk_65mhz),.reset(reset),.r({goal_pixel[11:8],4'h0}),.g({goal_pixel[7:4],4'h0}), .b({goal_pixel[3:0],4'h0}), .h(h_t), .s(s_t), .v(v_t));

    tracker my_tracker(
    .clk(clk_65mhz),
    .sw(sw), 
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
    
    
    
    
    
    
    // things to display on a 7 segment displays
    always_ff @(posedge clk_65mhz) begin
        case (sw[14:13])  
            2'b00:  data <= {h_t,s_t,v_t,4'h0,sw[3:0]};   // xxx(center)xxxx(size)x(switch)
            2'b01:  data <= {x_center[15:0],y_center[11:0], sw[3:0]};   // display 0123456 + sw[3:0]
            2'b10: data <= {goal_pixel,sw[3:0]}; 
            2'b11: data <= {radius,sw[3:0]};
            default: data <= {x_center[15:0],y_center[11:0], sw[3:0]};
        endcase;
     end
    
    
    
    
    
    /////////////INITIALIZE//////////////////
    logic signed [8:0] speed,turn;
    logic en1,ina1,inb1,ina2,inb2,en2;
    logic [7:0] speed_1,speed_2;
    logic signed [8:0] speed1,speed2;
    assign speed1 = {inb1,inb1?~speed_1 + 9'b1:speed_1};
    assign speed2 = {inb2,inb2?~speed_2 + 9'b1:speed_2};
    
    
    logic track,move;
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
          .activate_in(sw[1]),
          .sw2(scale), //whether to make the size twice
          .cam(sw[15]?thres:cam),
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
    logic [3:0] Kps,Kpt;
    logic [2:0] Kds,Kdt;
    logic [1:0] mode;
    
    control my_control( .clk_in(clk_65mhz),
                        .rst_in(reset),
                        .ready_in(frame_done_out),
                        .cur_pos_x(x_center[8:0]),
                        .cur_pos_y(y_center[8:0]),
                        .cur_rad(radius),
                        .goal_rad(goal_rad),
                        .params({Kps,Kds,Kpt,Kdt,mode}),
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
                        
    assign jc[5:0] = move?{en2,en1,ina2,inb2,ina1,inb1}:6'b0;
    ////////////////////////////////////////////////////////////////
    
    ///////////////switch FSM//////////////////////////////////////
    assign scale = ~move & sw[2];
    
    assign {Kps[3:1],Kds,Kpt[3:1],Kdt,mode[0]} = move?sw[14:2]:0;
    assign mode[1] = 1;
    assign Kps[0] = 0;
    assign Kpt[0] = 0;
    
    
    
    
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