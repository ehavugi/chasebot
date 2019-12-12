`timescale 1ns / 1ps
module xr_process(
    input clk,
    input rst,
    input [8:0] pre_x,
    input [6:0] pre_rad,goal_rad,
    output logic [8:0] x,
    output logic [6:0] rad
    );
    
    parameter KEEPFRAME = 32;
    logic off_screen;
    logic [8:0] old_x,valid_x;
    logic [6:0] old_r,valid_r;
    logic [7:0] counter;
    
    assign off_screen = &pre_x;
    always @(posedge clk) begin
        if(rst) begin
            old_x <= 0;
            old_r <= 0;
            valid_r <= 0;
            old_r <= 0;
            counter <= 0;
            x <= 9'd160;
            rad <= goal_rad;
        end
        else begin
            old_x <= pre_x;
            old_r <= pre_rad;
            
            if(off_screen) begin
                if(counter < KEEPFRAME) begin
                    x <= valid_x;
                    counter <= counter + 8'b1;
                end
                else begin
                    x <= 9'd160;
                    rad <= goal_rad;
                    end
            end
            else begin
                counter <= 0;
                valid_x <= pre_x;
                x <= pre_x;
                rad <= pre_rad;
                end
        end
    end
    
    
    
endmodule
