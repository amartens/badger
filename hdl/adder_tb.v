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

module adder_tb;
  parameter A_N_BITS = 3;
  parameter A_BIN_PT = 1;
  parameter A_DTYPE = 1;
  parameter B_N_BITS = 4;
  parameter B_BIN_PT = 3;
  parameter B_DTYPE = 0;
  parameter SUM_AB_N_BITS = 6;
  parameter SUM_AB_BIN_PT = 3;

  reg [A_N_BITS-1:0] a;
  reg [B_N_BITS-1:0] b;
  wire [SUM_AB_N_BITS-1:0] sum;
  
  initial begin
    a = 3'b0_0_0;         //      0 
    b = 4'b0_001;         // +  1/8
                          //    1/8
    #10 
    a = 3'b1_1_1;         //   -1/2
    b = 4'b0_001;         // +  1/8
                          //   -3/8
    #5 
    a = 3'b1_1_0;         //   -1
    b = 4'b0_100;         // +  1/2
                          //   -1/2
    #5 
    a = 3'b0_0_1;         //    1/2
    b = 4'b1_000;         // +  1
                          //    3/2
    #10 ;
    $finish;
  end //initial

  adder #(.A_N_BITS(A_N_BITS),  
        .A_BIN_PT(A_BIN_PT),
        .A_DTYPE(A_DTYPE),  
        .B_N_BITS(B_N_BITS),
        .BIN_PT_B(B_BIN_PT_B),
        .B_DTYPE(B_DTYPE),
        .SUM_AB_N_BITS(SUM_AB_N_BITS),
        .SUM_AB_BIN_PT(SUM_AB_BIN_PT)) a0 (a, b, sum);
  
  initial begin
	  $monitor("%t, a = \t(%d,%d)b'%b\t a_padded = \t(%d,%d)b'%b\n%t, b = \t(%d,%d)b'%b\t b_padded = \t(%d,%d)b'%b\n%t, sum = \t\t\t\t\t(%d,%d)b'%b", $time, A_N_BITS, A_BIN_PT, a, SUM_AB_N_BITS, SUM_AB_BIN_PT, a0.add0.a_padded, $time, B_N_BITS, B_BIN_PT, b, SUM_AB_N_BITS_OUT, SUM_AB_BIN_PT, a0.add0.b_padded, $time, SUM_AB_N_BITS, SUM_AB_BIN_PT, sum);
  end
endmodule //add_tb
