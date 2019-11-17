`timescale 1ns / 1ps


module debug_hardware(
                        input clk_100mhz,
                        input btnc,
                        input [15:0] sw,
                        output [7:0] jc
);


assign jc[3:0] = sw[5]? sw[3:0]:4'h0;

pwm ena(.clk_in(clk_100mhz), .rst_in(btnc), .level_in({sw[15:12],4'h0}), .pwm_out(jc[4]));
pwm enb(.clk_in(clk_100mhz), .rst_in(btnc), .level_in({sw[11:8],4'h0}), .pwm_out(jc[5]));

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