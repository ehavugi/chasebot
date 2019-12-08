`timescale 1ns / 1ps

//given the camera pixel, outputs everything to display
module initialize(
  input clk_65mhz,
  input reset,
  input [10:0] hcount,
  input [9:0] vcount,
  input vsync,
  input [3:0] directions, //up,down,left,right
  input confirm_in,
  input activate_in,
  input sw2, //whether to make the size twice
  input [11:0] cam,
  input [8:0] cur_pos_x,
  input [8:0] cur_pos_y,
  input [6:0] cur_rad,
  input signed [8:0] speed1,speed2,
  output logic [11:0] pixel_out,
  output logic [11:0] goal_pixel,
  output logic [6:0] goal_rad,
  output logic track,
  output logic move,
  //for debug
  output logic [2:0] state, 
  output logic [10:0] cursor_x,
  output logic [9:0] cursor_y,
  output logic up,down,left,right
  );

  logic [8:0] height;
  logic [9:0] width;
  
  assign height = sw2?9'd480:9'd240;
  assign width = sw2?10'd640:10'd320;
   
  
  //generate the blobs
  logic [11:0] box,box_confirmed,cursor,pad,speed_bar,selected_pixel,selected_buff,goal_pad;
  //logic [10:0] cursor_x;
  //logic [9:0] cursor_y;

  box box_gen(.x_in({2'b00,cur_pos_x}), .y_in({1'b0,cur_pos_y}), .hcount_in(hcount), .vcount_in(vcount), .radius_in(cur_rad), .pixel_out(box));
  box #(.COLOR(12'hf00)) confirmed_box_gen (.x_in({2'b00,cur_pos_x}), .y_in({1'b0,cur_pos_y}), .hcount_in(hcount), .vcount_in(vcount), .radius_in(cur_rad), .pixel_out(box_confirmed));
  cursor cursor_gen(.x_in(cursor_x), .y_in(cursor_y), .hcount_in(hcount), .vcount_in(vcount), .sw2(sw2), .pixel_out(cursor));
  colorpad colorpad_gen(.pixel_in(selected_buff), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(pad));
  colorpad goal_colorpad_gen(.pixel_in(goal_pixel), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(goal_pad));
  speed_bar speed_bar_gen(.speed1(speed1), .speed2(speed2), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(speed_bar));
  
  ///////////////////////////////////cursor control////////////////////////////////////////////////////////
  parameter CURSORSPEED = 3;
  parameter SAMPLESIZE = 1; // (0 -> 1, 1 -> 4, 2 -> 16)

//  logic up,down,left,right;
  logic [7:0] sum_r,sum_g,sum_b,sum_r_d,sum_g_d,sum_b_d;
  logic [3:0] shifted_r,shifted_g,shifted_b;
  
  assign shifted_r = sum_r >> 4;
  assign shifted_g = sum_g >> 4;
  assign shifted_b = sum_b >> 4;
  
  
  //single sample
  //assign selected_pixel = (vcount == cursor_y && hcount == cursor_x)? cam:selected_pixel;
  
  //assign selected_pixel = {shifted_r,shifted_g,shifted_b};
  logic confirm,confirm_serial,old_confirmed,activate;
  assign confirm = confirm_serial & ~old_confirmed; //pulse
  
  debounce db1(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[3]),.clean_out(up));
  debounce db2(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[2]),.clean_out(down));
  debounce db3(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[1]),.clean_out(left));
  debounce db4(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[0]),.clean_out(right));
  debounce db5(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(confirm_in),.clean_out(confirm_serial));
  debounce db6(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(activate_in),.clean_out(activate));
  
  always_ff @(posedge vsync) begin
    if(reset) begin
        cursor_x <= 11'h00f;
        cursor_y <= 10'h00f;
        
        
        //selected_buff <= 12'hff0;
    end else begin
        if (up) begin
            if(cursor_y < CURSORSPEED) cursor_y <= 0;
            else cursor_y <= cursor_y -  CURSORSPEED;
            
            end
    
        if (down) begin
            if (cursor_y > height - CURSORSPEED) cursor_y <= height;
            else cursor_y <= cursor_y + CURSORSPEED;
            end
        
        if (left) begin
            if(cursor_x < CURSORSPEED) cursor_x <= 0;
            else cursor_x <= cursor_x -  CURSORSPEED;
            end
    
        if (right) begin
            if (cursor_x > width - CURSORSPEED) cursor_x <= width;
            else cursor_x <= cursor_x + CURSORSPEED;
            end
        end
    end
    
//  always_ff @(posedge clk_65mhz) begin
//    //update pixel selected by cursor (average 4 or 16bits around)
//    if ((vcount >= cursor_y - SAMPLESIZE && vcount < cursor_y) && (hcount >= cursor_x - SAMPLESIZE && hcount < cursor_x + SAMPLESIZE)) begin
//            sum_r <= sum_r + cam[11:8];
//            sum_g <= sum_g + cam[7:4];
//            sum_b <= sum_b + cam[3:0];
//        end
//    if(vcount == 10'd550 && hcount ==11'd750) begin
//        sum_r <= 0;
//        sum_g <= 0;
//        sum_b <= 0;
//        selected_buff <= selected_buff + 1;
////        selected_buff <= 12'hf00;
//    end
//end //end always_ff
    

/////////////////////////////////////////////////end cursor control///////////////////////////////

////////////////////////////////////////////////main FSM//////////////////////////////////////////
parameter INITIALIZE = 0;
parameter SELECTED = 1;
parameter CONFIRMED = 2;
parameter MOVE = 3;
parameter PAUSE = 4;

//logic [1:0] state;
logic [2:0] old_state;
logic old_activate;
logic activated;
logic selected;
logic confirmed;

assign activated = ~old_activate & activate;     //if switched to activated
assign selected = (state==SELECTED && old_state==INITIALIZE);
assign confirmed = (state==CONFIRMED && old_state==SELECTED);

always_ff @(posedge clk_65mhz) begin
    if(reset) begin
        //initialize
        old_state <= 0;
        old_activate <= 0;
        state <= INITIALIZE;
        goal_rad <= 0;
        goal_pixel <= 0;
        pixel_out <= 0;
        old_confirmed <= 0;
        selected_buff <= 12'h000;
        sum_r <= 0;
        sum_g <= 0;
        sum_b <= 0;
    end else begin
    //pad 
        if(vcount == cursor_y && hcount == cursor_x) selected_buff <= cam;
        if ((vcount >= cursor_y - SAMPLESIZE && vcount < cursor_y) && (hcount >= cursor_x - SAMPLESIZE && hcount < cursor_x + SAMPLESIZE)) begin
            sum_r <= sum_r + cam[11:8];
            sum_g <= sum_g + cam[7:4];
            sum_b <= sum_b + cam[3:0];
        end
        if(vcount == 10'd550 && hcount == 11'd750) begin
            sum_r <= 0;
            sum_g <= 0;
            sum_b <= 0;
//            selected_buff <= {sum_r[5:2],sum_g[5:2],sum_b[5:2]};
//            selected_buff <= 12'hf00;
        end
        
        old_state <= state;
        old_activate <= activate;
        old_confirmed <= confirm_serial;
        //switch to initialize every time activated
        if(activated) state <= INITIALIZE;
        //get the goal pixel
        if(selected) goal_pixel <= selected_buff;
        //get the goal radius
        if(confirmed) goal_rad <= cur_rad;
        
        case(state)
          INITIALIZE: begin
            track <= 0;
            move <= 0;
            if(confirm) state <= SELECTED;
            pixel_out <= &cursor?cursor:cam+pad;
            end
          SELECTED: begin
            track <= 1;
            move <= 0;
            if(up | down | left | right) state <= INITIALIZE;
            if(confirm) state <= CONFIRMED;
            pixel_out <= (&cursor | &box)?cursor+box:cam + goal_pad;
            
            end
          CONFIRMED: begin
            track <= 1;
            move <= 0;
            if(~activate) state <= MOVE;
            pixel_out <= &box?box_confirmed:cam+speed_bar+goal_pad;
            end
          MOVE: begin
            track <= 1;
            move <= 1;
            pixel_out <= &box?box_confirmed:cam+goal_pad+speed_bar;
            if(confirm) state <= PAUSE;
            end
          PAUSE: begin
            track <= 0;
            move <= 0;
            pixel_out <= &box?box_confirmed:cam+goal_pad+speed_bar;
            if(confirm) state <= MOVE;
            end
        endcase
    end
end

endmodule
