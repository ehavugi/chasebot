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

module d_tf;

	// Inputs
	reg clk;
	reg sign;
	reg start;
	reg [7:0] dividend;
	reg [7:0] divider;

	// Outputs
	wire [7:0] quotient;
	wire [7:0] remainder;
	wire ready;

	// Instantiate the Unit Under Test (UUT)
	divider uut (
		.clk(clk), 
		.sign(sign), 
		.start(start), 
		.dividend(dividend), 
		.divider(divider), 
		.quotient(quotient), 
		.remainder(remainder), 
		.ready(ready)
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
		sign=0;
		dividend=50;
		divider=7;
		#10 start =1;
		#45 start=0;

	end
      
endmodule

