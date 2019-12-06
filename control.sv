`timescale 1ns / 1ps


module control(
                input clk_in,
                input rst_in,
                input ready_in,
                input [8:0] cur_pos_x,
                input [8:0] cur_pos_y,
                input [6:0] cur_rad,
                input [6:0] goal_rad,
                input [15:0] params,
                output logic signed [8:0] speed,
                output logic signed [8:0] turn
);

//camera size
parameter HEIGHT = 240;
parameter WIDTH = 320;

//modes
parameter FORWARD = 0;
parameter DIRECT = 1;
parameter GOALKEEP = 3;
parameter CHASE = 2;

//assign params
logic signed [4:0] Ksp;
logic signed [3:0] Ksd;
logic signed [4:0] Ktp;
logic signed [3:0] Ktd;
logic [1:0] mode;

assign {Ksp[3:0],Ksd[2:0],Ktp[3:0],Ktd[2:0],mode} = params;

assign Ksp[4] = 0;
assign Ksd[3] = 0;
assign Ktp[4] = 0;
assign Ktd[3] = 0;

//desired x,r
logic [8:0] x_d;
logic [6:0] r_d;
assign x_d = WIDTH >> 1;
assign r_d = goal_rad;

//current x,rad,dx,dr
logic [8:0] x;
logic [6:0] r;
logic [8:0] dx;
logic [6:0] dr;

//previous x,rad,dx,dr
logic [8:0] pre_x;
logic [6:0] pre_r;
logic [8:0] pre_dx;
logic [6:0] pre_dr;


//errors
logic signed [8:0] e_x;
logic signed [8:0] e_r;
logic signed [8:0] e_dx;
logic signed [8:0] e_dr;

assign e_x = x_d - x;   //abs less than 240
assign e_r = r_d - r;


//raw speed,turn
logic signed [16:0] raw_speed;
logic signed [16:0] raw_turn;


//threshold the output
logic [7:0] pass1;
logic [7:0] pass2;

threshold_by_abs threshold_speed(.signed_in(raw_speed), .threshold(16'h00ff), .signed_out({speed[8],pass1,speed[7:0]}));
threshold_by_abs threshold_turn(.signed_in(raw_turn), .threshold(16'h00ff), .signed_out({turn[8],pass2,turn[7:0]}));



always_comb begin
    case(mode)
        GOALKEEP:begin
                    raw_speed = (Ksp * e_x) + (Ksd * e_dx);
                    raw_turn = 0;

                end
        CHASE:  begin
                    raw_speed = (Ksp * e_r) + (Ksd * e_dr);
                    raw_turn = (Ktp * e_x) + (Ktd * e_dx);
                end
        DIRECT: begin
                   raw_speed = {params[15],8'd0,params[14:8],1'b0};
                   raw_turn = {params[7],8'd0,params[6:0],1'b0};
                end
        default:begin
                    raw_speed = 0;
                    raw_turn = 0;
                end
    endcase
end

always_ff @(posedge clk_in) begin
    if(rst_in) begin
        //initialize
        x <= 0;
        r <= 0;
        dx <= 0;
        dr <= 0;
        pre_x <= 0;
        pre_r <= 0;
        pre_dx <= 0;
        pre_dr <= 0;
        end

    else begin
        if(ready_in) begin
            x <= cur_pos_x;
            r <= cur_rad;
            e_dx <= x - cur_pos_x;
            e_dr <= r - cur_rad;
        end
    end
end
endmodule



module threshold_by_abs(
	input signed [16:0] signed_in,
	input [15:0] threshold,
	output signed [16:0] signed_out
);

logic sign;
logic [15:0] abs;

assign sign = signed_in[16];
assign signed_out[16] = sign;

assign abs = sign?~signed_in[15:0] + 16'h0001:signed_in[15:0];
assign signed_out[15:0] = (abs <= threshold)? signed_in[15:0]:(sign?~threshold+16'h0001:threshold);
endmodule