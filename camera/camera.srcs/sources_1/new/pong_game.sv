`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
//
// pong_game: the game itself!
//
////////////////////////////////////////////////////////////////////////////////

module pong_game (
   input vclock_in,        // 65MHz clock
   input reset_in,         // 1 to initialize module
   input up_in,            // 1 when paddle should move up
   input down_in,          // 1 when paddle should move down
   input [3:0] pspeed_in,  // puck speed in pixels/tick 
   input [10:0] hcount_in, // horizontal index of current pixel (0..1023)
   input [9:0]  vcount_in, // vertical index of current pixel (0..767)
   input hsync_in,         // XVGA horizontal sync signal (active low)
   input vsync_in,         // XVGA vertical sync signal (active low)
   input blank_in,         // XVGA blanking (1 means output black pixel)
        
   output phsync_out,       // pong game's horizontal sync
   output pvsync_out,       // pong game's vertical sync
   output pblank_out,       // pong game's blanking
   output logic [11:0] pixel_out,  // pong game's pixel  // r=23:16, g=15:8, b=7:0 
   output reg [27:0] digit // digits to display on LED
   );
   
   assign phsync_out = hsync_in;
   assign pvsync_out = vsync_in;
   assign pblank_out = blank_in;  
   // block size parameters
   parameter[10:0] paddle_w=16;
   parameter[9:0] paddle_h=126;
   parameter[10:0] center_blob_size=128;
   parameter[9:0] star_h=256;
   parameter[10:0] star_w=240;
   parameter[9:0] screen_h=768;
   parameter[10:0] screen_w=1028;
  
  //flags and variable
  reg x_sign=1'b1; // x direction flag
  reg y_sign=1'b1; // y direction flag
  reg halt=0; // stop the game flag
  reg[10:0] x_in=screen_w/2-star_w/2;
  reg[9:0] y_in=screen_h/2-star_h/2;
  reg [9:0] y_paddle=screen_h/2-paddle_h/2;
  
  reg [7:0] points=0;
  reg points_flag=1;
  
  parameter m=1;
  parameter n=1;
   ///pixels
   logic [11:0] pixel_puck;
   logic [11:0] pixel_paddle;
   logic [11:0] pixel_center;
   reg  [3+n:0] r_blended;
   reg  [3+n:0] g_blended;
   reg  [3+n:0] b_blended;
   digits seconds(.clk(vclock_in),.reset(reset_in),.halt(halt),.points(points), .digit(digit));

   
   // alpha bending using 1/2 
   always_ff @(posedge vclock_in) begin
    if ((pixel_puck>0)&(pixel_center>0)) // check 
        begin
             r_blended<=(pixel_puck[11:8]>>n)*m+pixel_center[11:8]-(pixel_center[11:8]>>n)*m;
             g_blended<=(pixel_puck[7:4]>>n)*m+pixel_center[7:4]-(pixel_center[7:4]>>n)*m;
             b_blended<=(pixel_puck[3:0]>>n)*m+pixel_center[3:0]-(pixel_center[3:0]>>n)*m;
             pixel_out<={r_blended[3:0],g_blended[3:0],b_blended[3:0]};
        end
            
        else    
           begin
                r_blended=(pixel_puck[11:8]+pixel_paddle[11:8]+pixel_center[11:8]);
                g_blended=(pixel_puck[7:4]+pixel_paddle[7:4]+pixel_center[7:4]);
                b_blended=(pixel_puck[3:0]+pixel_paddle[3:0]+pixel_center[3:0]);
                pixel_out={r_blended[3:0],g_blended[3:0],b_blended[3:0]};
           end                        
    end
        

   // control the pong 
    always_ff @(posedge vsync_in)  begin
         if (reset_in)
                begin 
                    y_paddle<=screen_h/2-paddle_h/2; // move the paddle in middle
                    halt<=1'b0; // start the  game
                     // set it to start in middle and move south east
                    x_in<=screen_h/2-paddle_h/2;
                    y_in<=383-120;
                    x_sign<=1'b1;
                    y_sign<=1'b1;
                    points<=0;
                 end 
                
      else
         begin
                 if (down_in & y_paddle<764-128) y_paddle<=y_paddle+4; // make it move down, but not out of screen
                 else if (up_in & y_paddle>4) y_paddle<=y_paddle-4;        
                 if (x_in<=16+pspeed_in) begin
                    if (y_paddle<(y_in+256) & (y_paddle+128>y_in))
                        begin 
                             x_sign<=1'b1;           
                             x_in<=x_in+pspeed_in;
                             y_sign<=y_sign;
                             if  (points_flag) 
                                 begin
                                     points<=points+1 ; // to avoid count points more than once for a single collision
                                     points_flag<=0;
                                end
                       end
                    else begin  
                        halt<=1'b1;     
                        x_sign<=1'b0;    
                        y_in<=y_in;
                        x_in<=x_in+pspeed_in;
                        y_sign<=y_sign;   
                    end;
                end;

        if (halt) 
            begin
                x_sign<=x_sign; // halt pong, wait for a rest to flip halt
                y_in<=y_in;
                x_in<=x_in;
                y_sign<=y_sign;
                points<=points;
            end
       else begin
        // x direction control                
                if (x_in>=screen_w-star_w-pspeed_in) 
                   begin
                     x_sign<=1'b0;
                     points_flag<=1'b1;
                  end
                else if (x_in<pspeed_in+pspeed_in) x_sign<=1'b1;
                else x_sign<=x_sign;
                // y direction control 
                if (y_in<=pspeed_in+pspeed_in) y_sign<=1'b1;
                else if (y_in>screen_h-star_h-pspeed_in) y_sign<=1'b0;
                else  y_sign<=y_sign;
                 
             // changing directions // position updates   
                if( x_sign)  x_in<=x_in+pspeed_in; 
                else x_in<=x_in-pspeed_in;
                if (y_sign) y_in<=y_in+pspeed_in;
                else y_in<=y_in-pspeed_in;    
       end 
   end
end
    // include the left paddle 
      blob #(.WIDTH(paddle_w),.HEIGHT(paddle_h),.COLOR(12'hFF0))// yellow,
          left_paddle(.x_in(11'd0),
                      .hcount_in(hcount_in),
                      .y_in(y_paddle),
                      .vcount_in(vcount_in),
                      .pixel_out(pixel_paddle));
   
   
   
   
   // include the center red rectangular block
     blob #(.WIDTH(center_blob_size),.HEIGHT(center_blob_size),.COLOR(12'hF00))// RED,
          center(.x_in(screen_w/2-center_blob_size/2),
                      .hcount_in(hcount_in),
                      .y_in(screen_h/2-center_blob_size/2),
                      .vcount_in(vcount_in),
                      .pixel_out(pixel_center));
  
    
    
    // include the star 
    picture_blob pic(.pixel_clk_in(vclock_in),
                     .x_in(x_in),
                     .hcount_in(hcount_in),
                     .y_in(y_in),
                     .vcount_in(vcount_in),
                    .pixel_out(pixel_puck)); 

endmodule