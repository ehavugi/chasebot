`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Updated 8/10/2019 Lab 3
// Updated 8/12/2018 V2.lab5c
// Create Date: 10/1/2015 V1.0
// Design Name:
// Module Name: labkit
//
//////////////////////////////////////////////////////////////////////////////////

module init_test(
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

    wire [31:0] data;      //  instantiate 7-segment display; display (8) 4-bit hex
    wire [6:0] segments;
    assign {cg, cf, ce, cd, cc, cb, ca} = segments[6:0];
    display_8hex display(.clk_in(clk_65mhz),.data_in(data), .seg_out(segments), .strobe_out(an));
    //assign seg[6:0] = segments;
    assign  dp = 1'b1;  // turn off the period

    //assign led = sw;                        // turn leds on
    assign led[3:0] = dir;
    assign data = {2'b0,cursor_y,1'b0,cursor_x,2'b00,state,sw[3:0]};   // display 0123456 + sw[3:0]
//    assign led16_r = btnl;                  // left button -> red led
//    assign led16_g = btnc;                  // center button -> green led
//    assign led16_b = btnr;                  // right button -> blue led
//    assign led17_r = btnl;
//    assign led17_g = btnc;
//    assign led17_b = btnr;

    wire [10:0] hcount;    // pixel on current line
    wire [9:0] vcount;     // line number
    wire hsync, vsync, blank;
    wire [11:0] pixel;
    reg [11:0] rgb;    
    xvga xvga1(.vclock_in(clk_65mhz),.hcount_out(hcount),.vcount_out(vcount),
          .hsync_out(hsync),.vsync_out(vsync),.blank_out(blank));


    // btnc button is user reset
    wire reset;
    //debounce db1(.reset_in(sw[0]),.clock_in(clk_65mhz),.noisy_in(btnc),.clean_out(reset));
    assign reset = sw[0];
    
    logic xclk;
    logic[1:0] xclk_count;
    
    logic pclk_buff, pclk_in;
    logic vsync_buff, vsync_in;
    logic href_buff, href_in;
    logic[7:0] pixel_buff, pixel_in;
    
    logic [11:0] cam;
    logic [11:0] frame_buff_out;
    logic [15:0] output_pixels;
    logic [15:0] old_output_pixels;
    logic [12:0] processed_pixels;
    logic [3:0] red_diff;
    logic [3:0] green_diff;
    logic [3:0] blue_diff;
    logic valid_pixel;
    logic frame_done_out;
    
    logic [16:0] pixel_addr_in;
    logic [16:0] pixel_addr_out;
    
    assign xclk = (xclk_count >2'b01);
    assign jbclk = xclk;
    assign jdclk = xclk;
    
    assign red_diff = (output_pixels[15:12]>old_output_pixels[15:12])?output_pixels[15:12]-old_output_pixels[15:12]:old_output_pixels[15:12]-output_pixels[15:12];
    assign green_diff = (output_pixels[10:7]>old_output_pixels[10:7])?output_pixels[10:7]-old_output_pixels[10:7]:old_output_pixels[10:7]-output_pixels[10:7];
    assign blue_diff = (output_pixels[4:1]>old_output_pixels[4:1])?output_pixels[4:1]-old_output_pixels[4:1]:old_output_pixels[4:1]-output_pixels[4:1];

    
    
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
        old_output_pixels <= output_pixels;
        xclk_count <= xclk_count + 2'b01;
//        if (sw[3])begin
//            //processed_pixels <= {red_diff<<2, green_diff<<2, blue_diff<<2};
//            processed_pixels <= output_pixels - old_output_pixels;
//        end else if (sw[4]) begin
//            if ((output_pixels[15:12]>4'b1000)&&(output_pixels[10:7]<4'b1000)&&(output_pixels[4:1]<4'b1000))begin
//                processed_pixels <= 12'hF00;
//            end else begin
//                processed_pixels <= 12'h000;
//            end
//        end else if (sw[5]) begin
//            if ((output_pixels[15:12]<4'b1000)&&(output_pixels[10:7]>4'b1000)&&(output_pixels[4:1]<4'b1000))begin
//                processed_pixels <= 12'h0F0;
//            end else begin
//                processed_pixels <= 12'h000;
//            end
//        end else if (sw[6]) begin
//            if ((output_pixels[15:12]<4'b1000)&&(output_pixels[10:7]<4'b1000)&&(output_pixels[4:1]>4'b1000))begin
//                processed_pixels <= 12'h00F;
//            end else begin
//                processed_pixels <= 12'h000;
//            end
//        end else begin
            processed_pixels = {output_pixels[15:12],output_pixels[10:7],output_pixels[4:1]};
//        end
            
    end
    assign pixel_addr_out = sw[2]?((hcount>>1)+(vcount>>1)*32'd320):hcount+vcount*32'd320;
    assign cam = sw[2]&&((hcount<640) &&  (vcount<480))?frame_buff_out:~sw[2]&&((hcount<320) &&  (vcount<240))?frame_buff_out:12'h000;

logic [3:0] red,green, blue;
logic[11:0] thres;
assign {red,green,blue}=cam;
logic [27:0] size;
logic [15:0] size_x;
logic [15:0] size_;
logic [15:0] pos_x;
logic [15:0] pos_y;

logic [26:0] count_f=0;
always @(posedge clk_65mhz) begin
    if (count_f<65000000) begin
        count_f<=count_f+1;
    end
    else begin
        count_f<=0;
        size_<=size_x;
    end
end

always @(posedge clk_65mhz) begin
    if ((red>(green+4))&&(red>(blue+4))) begin
        thres<=cam;
        size<=size+1;
        pos_x<=pos_x+hcount;
        pos_y<=pos_y+vcount;
        if (vsync) size_x<=size;
     end
    else begin thres=12'b0;
         end

end
                                        
   camera_read  my_camera(.p_clock_in(pclk_in),
                          .vsync_in(vsync_in),
                          .href_in(href_in),
                          .p_data_in(pixel_in),
                          .pixel_data_out(output_pixels),
                          .pixel_valid_out(valid_pixel),
                          .frame_done_out(frame_done_out));
   
    // UP and DOWN buttons for pong paddle
//    wire up,down,left,right;
//    debounce db2(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnu),.clean_out(up));
//    debounce db3(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnd),.clean_out(down));
//    debounce db4(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnl),.clean_out(left));
//    debounce db5(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnr),.clean_out(right));

    wire phsync,pvsync,pblank;
    pong_game pg(.vclock_in(clk_65mhz),.reset_in(reset),
                .up_in(up),.down_in(down),.pspeed_in(sw[15:12]),
                .hcount_in(hcount),.vcount_in(vcount),
                .hsync_in(hsync),.vsync_in(vsync),.blank_in(blank),
                .phsync_out(phsync),.pvsync_out(pvsync),.pblank_out(pblank),.pixel_out(pixel));

    wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767 |
                   hcount == 512 | vcount == 384);

    reg b,hs,vs;
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////
    //
    //TEST THE INITIALIZE
    //
    //////////////////////////////////////////////////////////////////////////////////////
    
    logic [6:0] goal_rad;
    logic [11:0] goal_pixel,pixel_out;
    logic track,move;
    logic [1:0] state;
    logic [10:0] cursor_x;
    logic [9:0] cursor_y;
    logic [3:0] dir;
    
    initialize initializer(
          .clk_65mhz(clk_65mhz),
          .reset(reset),
          .hcount(hcount),
          .vcount(vcount),
          .vsync(vsync_in),
          .directions({btnu,btnd,btnl,btnr}), //up,down,left,right
          .confirm_in(btnc),
          .activate_in(sw[15]),
          .sw2(sw[2]), //whether to make the size twice
          .cam(cam),
          .cur_pos_x({sw[14:11],4'b0}),
          .cur_pos_y({sw[10:7],4'b0}),
          .cur_rad({sw[6:4],3'b0}),
          .speed1(9'sd100),
          .speed2(-9'sd150),
          .pixel_out(pixel_out),
          .goal_pixel(goal_pixel),
          .goal_rad(goal_rad),
          .track(track),
          .move(move),
          //for debug
          .state(state),
          .cursor_x(cursor_x),
          .cursor_y(cursor_y),
          .up(dir[3]), 
          .down(dir[1]), 
          .left(dir[2]), 
          .right(dir[0])
          );
    
//    //camera size
//    parameter WIDTH = 320;
//    parameter HEIGHT = 240;
//    //cursor;
//    parameter SPEED = 3;
//    parameter THICKNESS = 2;
//    //blob pixels
//    logic [11:0] box,cursor,pad;
//    logic [10:0] cursor_x;
//    logic [9:0] cursor_y;
//    logic [15:0] cursor_pixel;  //selected color
    
//    //control cursor
////    always_ff @(posedge clk_100mhz) begin
        
////    end
     
//    //assign cursor_pixel = ((hcount > cursor_x -THICKNESS) && (hcount <= cursor_x + THICKNESS))? cam: cursor_pixel;
    
//    always_comb begin
//        if (hcount == 0 && vcount == 0) cursor_pixel = 0;
//        if (((hcount > cursor_x -THICKNESS) && (hcount <= cursor_x + THICKNESS)) && ((vcount > cursor_y -THICKNESS) && (vcount <= cursor_y + THICKNESS))) begin
//            cursor_pixel = cursor_pixel + cam;
//        end
//    end
    
//    always_ff @(posedge vsync_in) begin
//        if(reset) begin
//            cursor_x <= 0;
//            cursor_y <= 0;
//            //cursor_pixel <= 12'hfff;
//        end else begin
//            if (up) begin
//                if(cursor_y < SPEED) cursor_y <= 0;
//                else cursor_y <= cursor_y -  SPEED;
//            end
//            if (down) begin
//                if (cursor_y > HEIGHT - SPEED) cursor_y <= HEIGHT;
//                else cursor_y <= cursor_y + SPEED;
//            end
//            if (right) begin
//                if (cursor_x > WIDTH - SPEED) cursor_x <= WIDTH;
//                else cursor_x <= cursor_x + SPEED;
//            end
//            if (left) begin
//                if (cursor_x < SPEED) cursor_x <= 0;
//                else cursor_x <= cursor_x -  SPEED;
//            end
//        end
//    end
    
//    //blobs
//    box mybox(.x_in({sw[15:13],4'hf}), .hcount_in(hcount), .y_in({sw[12:10],4'hf}), .vcount_in(vcount), .radius_in({sw[9:7],3'h7}), .pixel_out(box));
//    cursor mycur(.x_in(cursor_x), .hcount_in(hcount), .y_in(cursor_y), .vcount_in(vcount), .pixel_out(cursor));
//    colorpad mypad(.hcount_in(hcount), .vcount_in(vcount), .pixel_in(cursor_pixel >> 4), .pixel_out(pad));
    
    
    
    
    always_ff @(posedge clk_65mhz) begin
      if (sw[1:0] == 2'b01) begin
         // 1 pixel outline of visible area (white)
         hs <= hsync;
         vs <= vsync;
         b <= blank;
         rgb <= {12{border}};
      end else if (sw[1:0] == 2'b10) begin
         // color bars
         hs <= hsync;
         vs <= vsync;
         b <= blank;
         rgb <= {{4{hcount[8]}}, {4{hcount[7]}}, {4{hcount[6]}}} ;
     end else if (sw[1:0] == 2'b11) begin
         // color bars
         hs <= hsync;
         vs <= vsync;
         b <= blank;
         rgb <= cam;
      end else begin
         // default: pong
         hs <= phsync;
         vs <= pvsync;
         b <= pblank;
//         rgb <= pixel;
//         rgb <= cam;
//         rgb<=thres;

         //rgb <= (&box | &cursor)? box + cursor:cam + pad;
         rgb <= pixel_out;
      end
    end

//    assign rgb = sw[0] ? {12{border}} : pixel ; //{{4{hcount[7]}}, {4{hcount[6]}}, {4{hcount[5]}}};

    // the following lines are required for the Nexys4 VGA circuit - do not change
    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

endmodule