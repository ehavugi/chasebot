//////////////////////////////////////////////////////////////////////
//
// blob: generate rectangle on screen
//
//////////////////////////////////////////////////////////////////////
module box
   #(parameter THICKNESS = 2,
               COLOR = 12'hFFF)  // default color: white
   (input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    input [6:0] radius_in,
    output logic [11:0] pixel_out);
    
    logic [6:0] inner;  //length to specify inside the box
    assign inner = radius_in - THICKNESS;
    
//assumming the ball is always fully inside the picture
   always_comb begin
    //if inside outside frame
      if ((hcount_in >= (x_in-radius_in) && hcount_in < (x_in+radius_in)) &&
	 (vcount_in >= (y_in-radius_in) && vcount_in < (y_in+radius_in))) begin
           //if outside inside frame
	       if (~(hcount_in >= (x_in-inner) && hcount_in < (x_in+inner)) |
	           ~(vcount_in >= (y_in-inner) && vcount_in < (y_in+inner))) begin
               pixel_out = COLOR;
           end
           else pixel_out = 0;
	   end
      else pixel_out = 0;
   end
endmodule

module cursor
    #(parameter THICKNESS = 1,
                COLOR = 12'hFFF, // default color: white
                WIDTH = 320,    //display width
                HEIGHT = 240    //display height
                ) 
    (input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);
    
    always_comb begin
        if ((hcount_in <= WIDTH && vcount_in == y_in) | (vcount_in <= HEIGHT && hcount_in == x_in)) pixel_out = COLOR;
        else pixel_out = 0;
    end

endmodule


module colorpad
    #(parameter WIDTH = 30,    //pad width
                HEIGHT = 30,    //pad height
                X = 800,        //pad x
                Y = 600         //pad y
                )
    (input [10:0] hcount_in,
    input [9:0] vcount_in,
    input [11:0] pixel_in,
    output logic [11:0] pixel_out);
    
    always_comb begin
        if ((hcount_in >= X && hcount_in < (X+WIDTH)) && (vcount_in >= Y && vcount_in < (Y+HEIGHT))) pixel_out = pixel_in;
        else pixel_out = 0;
    end
    
endmodule
   