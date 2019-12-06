`timescale 1ns / 1ps

module motor_out(input clk_in,
                input rst_in,
                input[7:0] offset,  //minimum speed needed to drive the car
                input signed [8:0] speed_in,
                input signed [8:0] turn_in,
                output logic [5:0] motor_out,    //en1,ina1,inb1,ina2,inb2,en2
                output logic [7:0] speed_1,speed_2
    );
    
    
logic signed [9:0] raw_motor1;
logic signed [9:0] raw_motor2;
logic [8:0] expanded_1;
logic [8:0] expanded_2;
logic [7:0] speed_1_offset; //without offset
logic [7:0] speed_2_offset; //without offset

logic forward_1;
logic forward_2;

assign raw_motor1 = speed_in - (turn_in >>> 1);
assign raw_motor2 = speed_in + (turn_in >>> 1);

assign forward_1 = ~raw_motor1[9];
assign forward_2 = ~raw_motor2[9];

assign expanded_1 = forward_1?raw_motor1[8:0]:~raw_motor1[8:0] + 9'h001;
assign expanded_2 = forward_2?raw_motor2[8:0]:~raw_motor2[8:0] + 9'h001;

assign speed_1_offset = expanded_1[8]?8'hff:expanded_1[7:0];
assign speed_2_offset = expanded_2[8]?8'hff:expanded_2[7:0];

assign speed_1 = (speed_1_offset>8'hff-offset)?8'hff:speed_1_offset+offset;
assign speed_2 = (speed_2_offset>8'hff-offset)?8'hff:speed_2_offset+offset;

pwm en1(.clk_in(clk_in), .rst_in(rst_in), .level_in(speed_1), .pwm_out(motor_out[5]));
pwm en2(.clk_in(clk_in), .rst_in(rst_in), .level_in(speed_2), .pwm_out(motor_out[0]));

assign motor_out[4:1] = {forward_1,~forward_1,forward_2,~forward_2};



endmodule


module pwm (input clk_in, input rst_in, input [7:0] level_in, output logic pwm_out);
    logic [7:0] count;
    assign pwm_out = count<level_in;
    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            count <= 8'b0;
        end else begin
            count <= count+8'b1;
        end
    end
endmodule