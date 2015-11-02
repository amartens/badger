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

module add_tb;
  parameter N_BITS_A = 3;
  parameter BIN_PT_A = 1;
  parameter N_BITS_B = 4;
  parameter BIN_PT_B = 3;
  parameter N_BITS_OUT = 6;
  parameter BIN_PT_OUT = 3;

  reg [N_BITS_A-1:0] a;
  reg [N_BITS_B-1:0] b;
  wire [N_BITS_OUT-1:0] sum;

  
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
    b = 4'b1_100;         // + -1/2
                          //   -3/2
    #5 
    a = 3'b0_1_1;         //    3/2
    b = 4'b1_110;         // + -1/4
                          //    5/4
    #10 ;
    $finish;
  end //initial

  add #(.N_BITS_A(N_BITS_A),  
        .BIN_PT_A(BIN_PT_A),  
        .N_BITS_B(N_BITS_B),
        .BIN_PT_B(BIN_PT_B)) a0 (a, b, sum);
  
  initial begin
	  $monitor("%t, a = \t(%d,%d)b'%b\t a_padded = \t(%d,%d)b'%b\n%t, b = \t(%d,%d)b'%b\t b_padded = \t(%d,%d)b'%b\n%t, sum = \t\t\t\t\t(%d,%d)b'%b", $time, N_BITS_A, BIN_PT_A, a, N_BITS_OUT, BIN_PT_OUT, a0.a_padded, $time, N_BITS_B, BIN_PT_B, b, N_BITS_OUT, BIN_PT_OUT, a0.b_padded, $time, N_BITS_OUT, BIN_PT_OUT, sum);
  end
endmodule //add_tb
