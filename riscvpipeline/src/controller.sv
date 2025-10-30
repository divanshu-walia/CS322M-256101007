// src/controller.sv
// Contains the controller, main decoder, and ALU decoder.
// This logic operates in the ID stage.

module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7,
                
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic       Branch, // <-- ADDED BRANCH OUTPUT
               
                  output logic [1:0] ImmSrc,
                  output logic [4:0] ALUControl);

  logic [1:0] ALUOp;
  // PCSrc and Zero logic is now in the EX stage

  maindec md(op, ResultSrc, MemWrite, Branch, // Pass Branch up
             ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);
  aludec  ad(funct7, funct3, ALUOp, ALUControl);
  
endmodule

module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc, // <-- Branch is now an output
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp);
               
  logic [10:0] controls;

  // Added Branch to the control vector
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type
      7'b0001011: controls = 11'b1_xx_0_0_00_0_11_0; // RVX10
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x;
    endcase
endmodule

module aludec(input  logic [6:0] funct7, // Changed to a 7-bit input
              input  logic [2:0] funct3,
              input  logic [1:0] ALUOp,
              output logic [4:0] ALUControl);
              
  always_comb
    case(ALUOp)
      2'b00: ALUControl = 5'b00000; // Addition for ls/sw
      2'b01: ALUControl = 5'b00001; // Subtraction for beq
      2'b10: // R-type or I-type ALU
        case(funct3)
          3'b000: if(funct7 == 7'b0100000) ALUControl = 5'b00001; // sub
                  else                     ALUControl = 5'b00000; // add , addi
          3'b010: ALUControl = 5'b00101; // slt, slti
          3'b110: ALUControl = 5'b00011; // or, ori
          3'b111: ALUControl = 5'b00010; // and,andi
          default:ALUControl = 5'bxxxxx;
        endcase
      
      2'b11: // NEW : RVX10 Instructions
        case(funct7)
          7'b0000000: // ANDM, ORN , XNOR
            case(funct3)
              3'b000: ALUControl = 5'b01000; // ANDN
              3'b001: ALUControl = 5'b01001; // ORN
              3'b010: ALUControl = 5'b01010; // XNOR
              default:ALUControl = 5'bxxxxx;
            endcase
          7'b0000001: // MIN,MAX,MINU,MAXU
            case(funct3)
              3'b000: ALUControl = 5'b01011; // MIN
              3'b001: ALUControl = 5'b01100; // MAX
              3'b010: ALUControl = 5'b01101; // MINU
              3'b011: ALUControl = 5'b01110; // MAXU
              default:ALUControl = 5'bxxxxx;
            endcase
          7'b0000010: // ROL,ROR
            case(funct3)
              3'b000: ALUControl = 5'b01111; // ROL
              3'b001: ALUControl = 5'b10000; // ROR
              default:ALUControl = 5'bxxxxx;
            endcase
          7'b0000011: // ABS
            case(funct3)
              3'b000: ALUControl = 5'b10001; // ABS
              default: ALUControl = 'bxxxxx;
            endcase
          default: ALUControl = 5'bxxxxx;
        endcase
      default: ALUControl = 5'bxxxxx;
    endcase
endmodule