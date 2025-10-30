// src/datapath.sv
// This file contains all the datapath helper modules.
// These are the building blocks we will use to construct the
// five pipeline stages in riscvpipeline.sv.

// Register File
module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [ 4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];
  // read two ports combinationally
  // write third port on rising edge of clock
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3) rf[a3] <= wd3;
    
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

// ALU (with RVX10 extensions)
module alu(input  logic [31:0] a, b,
           input  logic [4:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  always_comb
      begin
        logic [4:0] shamt = b[4:0];
        
        case (alucontrol)
          // Standard ALU operations
          5'b00000: result = a + b;
          5'b00001: result = a - b;
          5'b00010: result = a & b;
          5'b00011: result = a | b;
          5'b00100: result = a ^ b;
          5'b00101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // slt
          5'b00110: result = a << shamt; // sll
          5'b00111: result = a >> shamt; // srl

          // New RVX10 Operations
          5'b01000: result = a & ~b; // ANDN
          5'b01001: result = a | ~b; // ORN
          5'b01010: result = ~(a ^ b); // XNOR
          5'b01011: result = ($signed(a) < $signed(b)) ? a : b; // MIN
          5'b01100: result = ($signed(a) > $signed(b)) ? a : b; // MAX
          5'b01101: result = (a < b) ? a : b; // MINU
          5'b01110: result = (a > b) ? a : b; // MAXU
          5'b01111: result = (shamt == 0) ? a : (a << shamt) | (a >> (32 - shamt)); // ROL
          5'b10000: result = (shamt == 0) ? a : (a >> shamt) | (a << (32 - shamt)); // ROR
          5'b10001: result = ($signed(a) >= 0) ? a : -a; // ABS
          
          default: result = 32'bx;
        endcase
      end
      
    assign zero = (result == 32'b0);
endmodule

// Simple Adder
module adder(input  [31:0] a, b,
             output [31:0] y);
  assign y = a + b;
endmodule

// Immediate Extender
module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);
              
  assign immext =
    (immsrc == 2'b00) ? {{20{instr[31]}}, instr[31:20]} :                           // I-type
    (immsrc == 2'b01) ? {{20{instr[31]}}, instr[31:25], instr[11:7]} :              // S-type
    (immsrc == 2'b10) ? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} : // B-type
    (immsrc == 2'b11) ? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type
    32'bx; // Default case
endmodule

// Parameterized Register (will be used for pipeline registers)
module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);
               
  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

// 2-input Multiplexer
module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);
  assign y = s ? d1 : d0; 
endmodule

// 3-input Multiplexer
module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);
  assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule