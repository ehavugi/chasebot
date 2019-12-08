`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:17:13 11/20/2018
// Design Name:   divider
// Module Name:   D:/junk_d/6.111/divider_test/d_tf.v
// Project Name:  divider_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: divider
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ipdivider_tb;

	// Inputs
	reg clk;
	reg sign;
	reg start;
	reg [15:0] dividend;
	reg [15:0] divider;

	// Outputs
	wire [15:0] quotient;
	wire [15:0] remainder;
	wire ready;

	// Instantiate the Unit Under Test (UUT)
	div_gen_0 uut (
		.aclk(clk), 
		.s_axis_dividend_tdata(dividend), 
		.s_axis_dividend_tvalid(1), 
		.s_axis_divisor_tdata(divider), 
		.s_axis_divisor_tvalid(1), 
		.m_axis_dout_tdata({quotient,remainder}),
		.m_axis_dout_tvalid(ready)
	);

   always #5 clk=!clk;
	
	initial begin
		// Initialize Inputs
		clk = 0;
		sign = 0;
		start = 0;
		dividend = 0;
		divider = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		dividend=16'd20;
		divider=16'd3;
		#10
		dividend =16'd1000;
		divider=16'd50;
		#400
		
		$finish;

	end
      
endmodule

