module adder(a, b, sum_ab);

  parameter integer N_BITS_A              = 4;
  parameter integer BIN_PT_A              = 3;
  parameter integer SIGNED_A              = 1;
  
  parameter integer N_BITS_B              = 4;
  parameter integer BIN_PT_B              = 2;
  parameter integer SIGNED_B              = 0;

  // TODO
  parameter integer N_BITS_OUT            = 6;
  parameter integer BIN_PT_OUT            = 3;
  parameter integer SIGNED_OUT            = 1;
  //0 = WRAP, 1 = SATURATE
  parameter integer OVERFLOW_STRATEGY     = 0;
  //0 = TRUNCATE, 1 = ROUND 
  parameter integer QUANTIZATION_STRATEGY = 0;

  input wire [N_BITS_A-1:0] a;
  input wire [N_BITS_B-1:0] b;
  output wire [N_BITS_OUT-1:0] sum_ab;

  // if inputs are unsigned, pad with 0
  localparam integer WHOLE_BITS_A     = N_BITS_A-BIN_PT_A;
  localparam integer WHOLE_BITS_B     = N_BITS_B-BIN_PT_B;
  localparam integer WHOLE_BITS_A_IN  = (SIGNED_A == 1) ? WHOLE_BITS_A : (WHOLE_BITS_A+1);
  localparam integer WHOLE_BITS_B_IN  = (SIGNED_B == 1) ? WHOLE_BITS_B : (WHOLE_BITS_B+1);

  localparam integer N_BITS_A_IN = WHOLE_BITS_A_IN + BIN_PT_A;
  localparam integer N_BITS_B_IN = WHOLE_BITS_B_IN + BIN_PT_B;

  wire [N_BITS_A_IN-1:0] a_in;
  assign a_in[N_BITS_A-1:0] = a;
  assign a_in[N_BITS_A_IN-1] = (SIGNED_A == 1) ? a[N_BITS_A-1] : 1'b0;

  wire [N_BITS_B_IN-1:0] b_in;
  assign b_in[N_BITS_B-1:0] = b;
  assign b_in[N_BITS_B_IN-1] = (SIGNED_B == 1) ? b[N_BITS_B-1] : 1'b0;
   
  // derived parameters for output of adder
  localparam integer WHOLE_BITS_ADD_OUT = (WHOLE_BITS_A_IN > WHOLE_BITS_B_IN) ? WHOLE_BITS_A_IN: WHOLE_BITS_B_IN;

  localparam integer BIN_PT_ADD_OUT = (BIN_PT_A > BIN_PT_B) ? BIN_PT_A: BIN_PT_B;
  localparam integer N_BITS_ADD_OUT = WHOLE_BITS_ADD_OUT + BIN_PT_ADD_OUT + 1; 
 
  wire [N_BITS_ADD_OUT-1:0] sum;

  add #(.N_BITS_A(N_BITS_A_IN),  
        .BIN_PT_A(BIN_PT_A),  
        .N_BITS_B(N_BITS_B_IN),
        .BIN_PT_B(BIN_PT_B)) add0 (a_in, b_in, sum);

  //TODO quantise and handle overflow if necessary
  assign sum_ab = sum; 

endmodule
