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
  input activate,
  input sw2, //whether to make the size twice
  input [11:0] cam,
  input [8:0] cur_pos_x,
  input [8:0] cur_pos_y,
  input [6:0] cur_rad,
  input signed [8:0] speed1,speed2,
  output logic pixel_out,
  output logic [11:0] goal_pixel,
  output logic [6:0] goal_rad,
  output logic track,
  output logic move,
  output logic [1:0] state //for debug
  );

  logic [8:0] height;
  logic [9:0] width;
  assign height = sw2?9'd480:9'd240;
  assign width = sw2?10'd640:10'd320;

  //generate the blobs
  logic [11:0] box,box_confirmed,cursor,pad,speed_bar,selected_pixel,goal_pad;
  logic [10:0] cursor_x;
  logic [9:0] cursor_y;

  box box_gen(.x_in({2'b00,cur_pos_x}), .y_in({1'b0,cur_pos_y}), .hcount_in(hcount), .vcount_in(vcount), .radius_in(cur_rad), .pixel_out(box));
  box #(.COLOR(12'hf00)) confirmed_box_gen (.x_in({2'b00,cur_pos_x}), .y_in({1'b0,cur_pos_y}), .hcount_in(hcount), .vcount_in(vcount), .radius_in(cur_rad), .pixel_out(box_confirmed));
  cursor cursor_gen(.x_in(cursor_x), .y_in(cursor_y), .hcount_in(hcount), .vcount_in(vcount), .sw2(sw2), .pixel_out(cursor));
  colorpad colorpad_gen(.pixel_in(selected_pixel), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(pad));
  colorpad goal_colorpad_gen(.pixel_in(goal_pixel), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(pad));
  speed_bar speed_bar_gen(.speed1(speed1), .speed2(speed2), .hcount_in(hcount), .vcount_in(vcount), .pixel_out(speed_bar));

  ///////////////////////////////////cursor control////////////////////////////////////////////////////////
  parameter CURSORSPEED = 2;
  parameter SAMPLESIZE = 2; // (0 -> 1, 1 -> 4, 2 -> 16)

  logic up,down,left,right;
  logic [8:0] sum_r,sum_g,sum_b;
  logic [4:0] shifted_r,shifted_g,shifted_b;
  assign shifted_r = sum_r << 4;
  assign shifted_g = sum_g << 4;
  assign shifted_b = sum_b << 4;

  //single sample
  //assign selected_pixel = (vcount == cursor_y && hcount == cursor_x)? cam:selected_pixel;

  assign selected_pixel = {shifted_r,shifted_g,shifted_b};

  debounce db1(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[3]),.clean_out(up));
  debounce db2(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[2]),.clean_out(down));
  debounce db3(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[1]),.clean_out(left));
  debounce db4(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(directions[0]),.clean_out(right));
  debounce db5(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(confirm_in),.clean_out(confirm));

  always_ff @(posedge clk_65mhz) begin
    if (up) begin
        if(cursor_y < CURSORSPEED) cursor_y <= 0;
        else cursor_y <= cursor_y -  CURSORSPEED;
        end

    if (down) begin
        if (cursor_y > height) cursor_y <= height;
        else cursor_y <= cursor_y + CURSORSPEED;
        end
    if (left) begin
        if(cursor_x < CURSORSPEED) cursor_x <= 0;
        else cursor_x <= cursor_x -  CURSORSPEED;
        end

    if (right) begin
        if (cursor_x > width) cursor_x <= width;
        else cursor_x <= cursor_x + CURSORSPEED;
        end

    //update pixel selected by cursor (average 4 or 16bits around)
    if(vsync) begin
        sum_r <= 0;
        sum_g <= 0;
        sum_b <= 0;
    end
    else begin
        if ((vcount > cursor_y - SAMPLESIZE && vcount <= cursor_y) && (hcount > cursor_x - SAMPLESIZE && hcount <= cursor_x + SAMPLESIZE)) begin
            sum_r <= sum_r + cam[11:8];
            sum_g <= sum_g + cam[7:4];
            sum_b <= sum_b + cam[3:0];
        end
    end
end //end always_ff

/////////////////////////////////////////////////end cursor control///////////////////////////////

////////////////////////////////////////////////main FSM//////////////////////////////////////////
parameter INITIALIZE = 0;
parameter SELECTED = 1;
parameter CONFIRMED = 2;
parameter MOVE = 0;

//logic [1:0] state;
logic [1:0] old_state;
logic old_activate;
logic activated;

assign activated = ~old_activate & activate;     //if switched to activated
always_ff @(posedge clk_65mhz) begin
    if(reset) begin
        //initialize
        old_state <= 0;
        old_activate <= 0;
        state <= INITIALIZE;
        cursor_x <= 0;
        cursor_y <= 0;
        goal_rad <= 0;
        goal_pixel <=0;
        pixel_out <= 0;
    end
    old_state <= state;
    old_activate <= activate;
    if(activated) state <= INITIALIZE;
    case(state)
      INITIALIZE: begin
        track <= 0;
        move <= 0;
        if(confirm) state <= SELECTED;
        pixel_out <= &cursor?cursor:cam + pad;
        end
      SELECTED: begin
        track <= 1;
        move <= 0;
        if(up | down | left | right) state <= INITIALIZE;
        pixel_out <= (&cursor | &box)?cursor+box:cam + pad;
        //get the goal pixel
        end
      CONFIRMED: begin
        track <= 1;
        move <= 0;
        if(~activate) state <= MOVE;
        pixel_out <= &box?box_confirmed:cam;
        goal_rad <= cur_rad;
        end
      MOVE: begin
        track <= 1;
        move <= 1;
        //pixel_out <= &box?box_confirmed:cam+goal_pad;
        pixel_out <= &box?box_confirmed:cam;
        end
    endcase
end

endmodule
