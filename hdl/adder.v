//this file is part of ratel.
//
//    ratel is free software: you can redistribute it and/or modify
//    it under the terms of the gnu general public license as published by
//    the free software foundation, either version 3 of the license, or
//    (at your option) any later version.
//
//    ratel is distributed in the hope that it will be useful,
//    but without any warranty; without even the implied warranty of
//    merchantability or fitness for a particular purpose.  see the
//    gnu general public license for more details.
//
//    you should have received a copy of the gnu general public license
//    along with ratel.  if not, see <http://www.gnu.org/licenses/>.

module adder(a, b, sum_ab);

  parameter integer A_N_BITS              = 4;
  parameter integer A_BIN_PT              = 3;
  parameter integer A_DTYPE               = 1;
  //0 = UNSIGNED, 1 = 2's COMPLEMENT, 2 = BOOLEAN  
  input wire [A_N_BITS-1:0] a;

  parameter integer B_N_BITS              = 4;
  parameter integer B_BIN_PT_B            = 2;
  parameter integer B_DTYPE               = 0;
  //0 = UNSIGNED, 1 = 2's COMPLEMENT, 2 = BOOLEAN  
  input wire [B_N_BITS-1:0] b;

  parameter integer SUM_AB_N_BITS         = 6;
  parameter integer SUM_AB_BIN_PT         = 3;
  parameter integer SUM_AB_DTYPE          = 1;
  //0 = UNSIGNED, 1 = 2's COMPLEMENT, 2 = BOOLEAN  
  output wire [SUM_AB_N_BITS-1:0] sum_ab;

  // TODO
  parameter integer OVERFLOW_STRATEGY     = 0;
  //0 = WRAP, 1 = SATURATE

  parameter integer QUANTIZATION_STRATEGY = 0;
  //0 = TRUNCATE, 1 = ROUND 

  // if inputs are unsigned, pad with 0
  localparam integer WHOLE_BITS_A     = A_N_BITS-A_BIN_PT;
  localparam integer WHOLE_BITS_B     = B_N_BITS-B_BIN_PT;
  localparam integer WHOLE_BITS_A_IN  = (A_DTYPE == 1) ? WHOLE_BITS_A : (WHOLE_BITS_A+1);
  localparam integer WHOLE_BITS_B_IN  = (B_DTYPE == 1) ? WHOLE_BITS_B : (WHOLE_BITS_B+1);

  localparam integer N_BITS_A_IN = WHOLE_BITS_A_IN + A_BIN_PT;
  localparam integer N_BITS_B_IN = WHOLE_BITS_B_IN + B_BIN_PT;

  wire [N_BITS_A_IN-1:0] a_in;
  assign a_in[A_N_BITS-1:0] = a;
  assign a_in[N_BITS_A_IN-1] = (A_DTYPE == 1) ? a[A_N_BITS-1] : 1'b0;

  wire [N_BITS_B_IN-1:0] b_in;
  assign b_in[B_N_BITS-1:0] = b;
  assign b_in[N_BITS_B_IN-1] = (B_DTYPE == 1) ? b[B_N_BITS-1] : 1'b0;
   
  // derived parameters for output of adder
  localparam integer WHOLE_BITS_ADD_OUT = (WHOLE_BITS_A_IN > WHOLE_BITS_B_IN) ? WHOLE_BITS_A_IN: WHOLE_BITS_B_IN;

  localparam integer BIN_PT_ADD_OUT = (A_BIN_PT > B_BIN_PT) ? A_BIN_PT: B_BIN_PT;
  localparam integer N_BITS_ADD_OUT = WHOLE_BITS_ADD_OUT + BIN_PT_ADD_OUT + 1; 
 
  wire [N_BITS_ADD_OUT-1:0] sum;

  add #(.N_BITS_A(N_BITS_A_IN),  
        .BIN_PT_A(A_BIN_PT),  
        .N_BITS_B(N_BITS_B_IN),
        .BIN_PT_B(B_BIN_PT)) add0 (a_in, b_in, sum);

  //TODO quantise and handle overflow if necessary
  assign sum_ab = sum; 

endmodule
