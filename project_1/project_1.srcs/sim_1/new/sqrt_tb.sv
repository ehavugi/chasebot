`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2019 10:34:04 PM
// Design Name: 
// Module Name: sqrt_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
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

module sqrt_tb;

	// Inputs
	reg clk;
	reg sign;
	reg start;

	logic [31:0] number;
    // Outputs

	logic [31:0] result;
	wire ready;

	// Instantiate the Unit Under Test (UUT)
	sqrt uut (
		.aclk(clk), 
		.s_axis_cartesian_tdata(number), 
		.s_axis_cartesian_tvalid(1), 
		.m_axis_dout_tdata(result),
		.m_axis_dout_tvalid(ready)
	);

   always #5 clk=!clk;
	
	initial begin
		// Initialize Inputs
		clk = 0;
		sign = 0;
		start = 0;
		number =32'd100;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		number=32'd25;
		#100;
		number=32'd3;
		#100
		number =32'd1000;
		number=32'd50;
		#800
		
		$finish;

	end
      
endmodule

