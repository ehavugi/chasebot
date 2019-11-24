//////////////////////////////////////////////////////////////////////
//
// blob: generate rectangle on screen
//
//////////////////////////////////////////////////////////////////////
module blob
   #(parameter COLOR = 12'hFFF)  // default color: white
   (input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    input [7:0] widht,height,
    output logic [11:0] pixel_out);

   always_comb begin
      if ((hcount_in >= x_in && hcount_in < (x_in+width)) &&
	 (vcount_in >= y_in && vcount_in < (y_in+height)))
	pixel_out = COLOR;
      else pixel_out = 0;
   end
endmodule


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


module speed_bar  //display a bar indicating speed of each motor
      #(parameter WIDTH=50, //length of the bar
                  HEIGHT =256, //height of the bar
                  X = 800,  //start pos
                  Y = 200,  //baseline pos
                  TOTAL = WIDTH*5,
                  COLOR = COLOR = 12'hF00 // default color: red, the baseline is white
      )
      (input [10:0] hcount_in,
      input [9:0] vcount_in,
      input signed [8:0] speed1,speed2,
      output logic [11:0] pixel_out);

      logic [10:0] x1,x2;
      logic [9:0] y1,y2;
      logic [11:0] motor1,motor2,bar;
      logic [7:0] abs1,abs2;

      assign x1 = X + WIDTH;
      assign x2 = X + WIDTH*3;
      assign y1 = speed1[8]?Y:Y+speed1[7:0];
      assign y2 = speed2[8]?Y:Y+speed2[7:0];
      assign abs1 = speed1[8]?~speed1[7:0]+8'b1:speed1[7:0];
      assign abs2 = speed2[8]?~speed2[7:0]+8'b1:speed2[7:0];

      assign pixel_out = &bar?bar:motor1 + motor2;

      blob m1 #(.COLOR(COLOR))
                (.x_in(x1), .y_in(y1), .hcount_in(hcount_in), .vcount_in(vcount_in), .width(WIDTH), .height(abs1), .pixel_out(motor1));
      blob m2 #(.COLOR(COLOR))
                (.x_in(x2), .y_in(y2), .hcount_in(hcount_in), .vcount_in(vcount_in), .width(WIDTH), .height(abs2), .pixel_out(motor2));

      always_comb begin
          if ((hcount_in >= X && hcount_in < (X+TOTAL)) && (vcount_in >= Y && vcount_in < (Y+1))) bar = 12'hFFF;
          else bar = 0;
      end



module arrow    //To be continued
    #(parameter WIDTH=50, //length of the bar
            HEIGHT =256, //height of the bar
            X = 800,  //start pos
            Y = 200,  //baseline pos
            TOTAL = WIDTH*5,
            COLOR = COLOR = 12'hF00 // default color: red, the baseline is white
            )
      (input [10:0] hcount_in,
      input [9:0] vcount_in,
      input signed [8:0] speed1,speed2,
      output logic [11:0] pixel_out);
