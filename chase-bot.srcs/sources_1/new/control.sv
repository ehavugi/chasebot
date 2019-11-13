`timescale 1ns / 1ps


module control(
                input clk_in,
                input rst_in,
                input ready_in,
                input [8:0] cur_pos_x,
                input [8:0] cur_pos_y,
                input [8:0] cur_rad,
                input [8:0] goal_rad,
                input [15:0] params,
                output logic signed [8:0] speed,
                output logic signed [8:0] turn
);

//camera size
parameter HEIGHT = 360;
parameter WIDTH = 480;

//modes
parameter GOALKEEP = 3;
parameter CHASE = 2;

//assign params
logic [3:0] Ksp;
logic [2:0] Ksd;
logic [3:0] Ktp;
logic [2:0] Ktd;
logic [1:0] mode;

assign {Ksp,Ksd,Ktp,Ktd,mode} = params;


//desired x,r
logic [8:0] x_d;
logic [8:0] r_d;
assign x_d = WIDTH >> 1;
assign r_d = goal_rad;

//current x,rad,dx,dr
logic [8:0] x;
logic [8:0] r;
logic [8:0] dx;
logic [8:0] dr;

//previous x,rad,dx,dr
logic [8:0] pre_x;
logic [8:0] pre_r;
logic [8:0] pre_dx;
logic [8:0] pre_dr;


//errors
logic signed [9:0] e_x;
logic signed [9:0] e_r;
logic signed [9:0] e_dx;
logic signed [9:0] e_dr;

assign e_x = x_d - x;
assign e_r = r_d - r;

always_comb begin
    case(mode)
        GOALKEEP:begin
                    speed = Ksp * e_x + Ksd * e_dx;
                    turn = 0;

                end
        CHASE:  begin
                    speed = Ksp * e_r + Ksd * e_dr;
                    turn = Ktp * e_x + Ktp * e_dx;
                end
        default:begin
                    speed = 0;
                    turn = 0;
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
