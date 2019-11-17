`timescale 1ns / 1ps


module configuration(
  input clk;
  input active;
  input confirm;
  input [3:0] commands; //up down left right
);
