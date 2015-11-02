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

module add(a, b, sum_ab);
  parameter integer N_BITS_A = 9;
  parameter integer BIN_PT_A = 6;
  parameter integer N_BITS_B = 9;
  parameter integer BIN_PT_B = 8;

  // derived parameters
  localparam integer WHOLE_BITS_A =       N_BITS_A-BIN_PT_A;
  localparam integer WHOLE_BITS_B =       N_BITS_B-BIN_PT_B;
  localparam integer WHOLE_BITS_OUT = (WHOLE_BITS_A > WHOLE_BITS_B) ? WHOLE_BITS_A: WHOLE_BITS_B;

  localparam integer BIN_PT_OUT = (BIN_PT_A > BIN_PT_B) ? BIN_PT_A: BIN_PT_B;
  localparam integer N_BITS_OUT = WHOLE_BITS_OUT + BIN_PT_OUT + 1; 

  input wire [N_BITS_A-1:0] a;
  input wire [N_BITS_B-1:0] b;
  output reg [N_BITS_OUT-1:0] sum_ab;

  // padding to align binary points
  localparam integer BIN_PT_PAD_A =       BIN_PT_OUT - BIN_PT_A;
  localparam integer BIN_PT_PAD_B =       BIN_PT_OUT - BIN_PT_B;

  // number of sign extension bits
  localparam integer WHOLE_BITS_PAD_A =   WHOLE_BITS_OUT - WHOLE_BITS_A + 1;
  localparam integer WHOLE_BITS_PAD_B =   WHOLE_BITS_OUT - WHOLE_BITS_B + 1;

  // sign extend and pad a,b
  wire a_sign = a[N_BITS_A-1]; 
  wire b_sign = b[N_BITS_B-1]; 
  wire [N_BITS_OUT-1:0] a_padded = {{WHOLE_BITS_PAD_A{a_sign}}, {a}, {BIN_PT_PAD_A{1'b0}}};
  wire [N_BITS_OUT-1:0] b_padded = {{WHOLE_BITS_PAD_B{b_sign}}, {b}, {BIN_PT_PAD_B{1'b0}}};

  // sum the padded 2's complement values
  always @ (a_padded, b_padded) begin
    sum_ab = a_padded + b_padded;
  end //always

endmodule
