// riscvsingle.sv

// RISC-V single-cycle processor
// From Section 7.6 of Digital Design & Computer Architecture
// 27 April 2020
// David_Harris@hmc.edu 
// Sarah.Harris@unlv.edu

// run 210
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)

// Single-cycle implementation of RISC-V (RV32I)
// User-level Instruction Set Architecture V2.2 (May 7, 2017)
// Implements a subset of the base integer instructions:
//    lw, sw
//    add, sub, and, or, slt, 
//    addi, andi, ori, slti
//    beq
//    jal
// Exceptions, traps, and interrupts not implemented
// little-endian memory

// 31 32-bit registers x1-x31, x0 hardwired to 0
// R-Type instructions
//   add, sub, and, or, slt
//   INSTR rd, rs1, rs2
//   Instr[31:25] = funct7 (funct7b5 & opb5 = 1 for sub, 0 for others)
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// I-Type Instructions
//   lw, I-type ALU (addi, andi, ori, slti)
//   lw:         INSTR rd, imm(rs1)
//   I-type ALU: INSTR rd, rs1, imm (12-bit signed)
//   Instr[31:20] = imm[11:0]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// S-Type Instruction
//   sw rs2, imm(rs1) (store rs2 into address specified by rs1 + immm)
//   Instr[31:25] = imm[11:5] (offset[11:5])
//   Instr[24:20] = rs2 (src)
//   Instr[19:15] = rs1 (base)
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:0]  (offset[4:0])
//   Instr[6:0]   = opcode
// B-Type Instruction
//   beq rs1, rs2, imm (PCTarget = PC + (signed imm x 2))
//   Instr[31:25] = imm[12], imm[10:5]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:1], imm[11]
//   Instr[6:0]   = opcode
// J-Type Instruction
//   jal rd, imm  (signed imm is multiplied by 2 and added to PC, rd = PC+4)
//   Instr[31:12] = imm[20], imm[10:1], imm[11], imm[19:12]
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode

//   Instruction  opcode    funct3    funct7
//   add          0110011   000       0000000
//   sub          0110011   000       0100000
//   and          0110011   111       0000000
//   or           0110011   110       0000000
//   slt          0110011   010       0000000
//   addi         0010011   000       immediate
//   andi         0010011   111       immediate
//   ori          0010011   110       immediate
//   slti         0010011   010       immediate
//   beq          1100011   000       immediate
//   lw	          0000011   010       immediate
//   sw           0100011   010       immediate
//   jal          1101111   immediate immediate

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if(DataAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end
    
endmodule

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, 
                       WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule

module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PC,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  logic       ALUSrc, RegWrite, Jump, Zero;
  logic [1:0] ResultSrc, ImmSrc;
  logic [4:0] ALUControl;//1)Widen the ALU Bits from 3 bit to 5 bit.
                         //2)Then update the controller and aludec modules ports accordingly.

  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero, //6) changing Instr[30] to Instr[31:25] since funct7 is 7 bits
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump,
               ImmSrc, ALUControl);
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl,
              Zero, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule

module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7, //4)Passing full bits for funct7 funct7b5 -> funct7
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       PCSrc, ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic [1:0] ImmSrc,
                  output logic [4:0] ALUControl); //3)Widen the output ALU bits also

  logic [1:0] ALUOp;
  logic       Branch;
  // logic       PCSrc;

  maindec md(op, ResultSrc, MemWrite, Branch,
             ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);
  // aludec  ad(op, funct3, funct7, ALUOp, ALUControl); //5) Passing full bits for funct7 funct7b5 -> funct7
                //  input  logic       Zero,
  aludec  ad(funct7, funct3, ALUOp, ALUControl);

  assign PCSrc = Branch & Zero | Jump;
endmodule

module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp);

  logic [10:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type
      7'b0001011: controls = 11'b1_xx_0_0_00_0_11_0; // 8) RVX10 : Adding this new ALUOp '11'
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

// We will modify the ALU to support the 
// module aludec(input  logic       opb5,
//               input  logic [2:0] funct3,
//               input  logic       funct7, //11) Wndening 3 bits to 5 bis
//               input  logic [1:0] ALUOp,
//               output logic [4:0] ALUControl); //9) Widening 3 bits to 5 bits
module aludec(input  logic [6:0] funct7, // Changed to a 7-bit input
              input  logic [2:0] funct3,
              input  logic [1:0] ALUOp,
              output logic [4:0] ALUControl);
  // logic  RtypeSub;
  // assign RtypeSub = funct7 & opb5;  // TRUE for R-type subtract instruction
  always_comb
    case(ALUOp) //10) INSTRUCTION DECODING FOR RVX10
        2'b00: ALUControl = 5'b00000; //Addition for ls/sw
      2'b01: ALUControl = 5'b00001; //Subtraction for beq
      2'b10: //R-type ot I-type ALU
        case(funct3)
          3'b000: if(funct7 == 7'b0100000) ALUControl = 5'b00001; //sub
                  else                     ALUControl = 5'b00000; //add , addi
          3'b010: ALUControl = 5'b00101; //slt, slti
          3'b110: ALUControl = 5'b00011; //or, ori
          3'b111: ALUControl = 5'b00010; //and,andi
          default:ALUControl = 5'bxxxxx; // ???
        endcase
      
      2'b11: //NEW : RVX10 Instructions
        case(funct7)
          7'b0000000: //ANDM, ORN , XNOR
            case(funct3)
              3'b000: ALUControl = 5'b01000; //ANDN
              3'b001: ALUControl = 5'b01001; //ORN
              3'b010: ALUControl = 5'b01010; //XNOR
              default:ALUControl = 5'bxxxxx; // ???
            endcase
          7'b0000001: //MIN,MAX,MINU,MAXU
            case(funct3)
              3'b000: ALUControl = 5'b01011; //MIN
              3'b001: ALUControl = 5'b01100; //MAX
              3'b010: ALUControl = 5'b01101; //MINU
              3'b011: ALUControl = 5'b01110; //MAXU
              default:ALUControl = 5'bxxxxx; // ???
            endcase

          7'b0000010: //ROL,ROR
            case(funct3)
              3'b000: ALUControl = 5'b01111; //ROL
              3'b001: ALUControl = 5'b10000; //ROR
              default:ALUControl = 5'bxxxxx; // ???

            endcase
          7'b0000011: //ABS
            case(funct3)
              3'b000: ALUControl = 5'b10001; //ABS
              default: ALUControl = 'bxxxxx; // ???
            endcase
          default: ALUControl = 5'bxxxxx; // ???
        endcase
        default: ALUControl = 5'bxxxxx; // ???
    endcase

endmodule

module datapath(input  logic        clk, reset,
                input  logic [1:0]  ResultSrc, 
                input  logic        PCSrc, ALUSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [4:0]  ALUControl, //7) Updating the ALUControl bits from 3 to 5 bits
                output logic        Zero,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData);

  logic [31:0] PCNext, PCPlus4, PCTarget;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;

  // next PC logic
  flopr #(32) pcreg(clk, reset, PCNext, PC); 
  adder       pcadd4(PC, 32'd4, PCPlus4);
  adder       pcaddbranch(PC, ImmExt, PCTarget);
  mux2 #(32)  pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, WriteData);
  extend      ext(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux2 #(32)  srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule

module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [ 4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  always_ff @(posedge clk)
    if (we3) rf[a3] <= wd3;	

  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

module adder(input  [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule

module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);

  // This logic is the same as the case statement but written in a way
  // that avoids the iverilog "constant selects" issue.
  assign immext =
    (immsrc == 2'b00) ? {{20{instr[31]}}, instr[31:20]} :                           // I-type
    (immsrc == 2'b01) ? {{20{instr[31]}}, instr[31:25], instr[11:7]} :              // S-type
    (immsrc == 2'b10) ? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} : // B-type
    (immsrc == 2'b11) ? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type
    32'bx; // Default case

endmodule
// module extend(input  logic [31:7] instr,
//               input  logic [1:0]  immsrc,
//               output logic [31:0] immext);
 
//   always_comb
//     case(immsrc) 
//                // I-type 
//       2'b00:   immext = {{20{instr[31]}}, instr[31:20]};  
//                // S-type (stores)
//       2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
//                // B-type (branches)
//       2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
//                // J-type (jal)
//       2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
//       default: immext = 32'bx; // undefined
//     endcase             
// endmodule

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("tests/riscvtest.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned
endmodule

module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

// module alu(input  logic [31:0] a, b,
//            input  logic [4:0]  alucontrol, //widen the bits from 3 to 5 bits
//            output logic [31:0] result,
//            output logic        zero);

//   logic [31:0] condinvb, sum;
//   logic        v;              // overflow
//   logic        isAddSub;       // true when is add or subtract operation

//   assign condinvb = alucontrol[0] ? ~b : b;
//   assign sum = a + condinvb + alucontrol[0];
//   assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
//                     ~alucontrol[1] & alucontrol[0];

//   always_comb 
  
//     case (alucontrol)
//       5'b00000:  result = sum;         // add
//       5'b00001:  result = sum;         // subtract
//       5'b00010:  result = a & b;       // and
//       5'b00011:  result = a | b;       // or
//       5'b00100:  result = a ^ b;       // xor
//       5'b00101:  result = sum[31] ^ v; // slt
//       5'b00110:  result = a << b[4:0]; // sll
//       5'b00111:  result = a >> b[4:0]; // srl


//     //New RVX10 Operations
//       5'b01000: result = a & ~b;        // ANDN
//       5'b01001: result = a | ~b;        //ORN
//       5'b01010: result = ~(a^b);        //XNOR
//       5'b01011: result = ($signed(a) < $signed(b)) ? a : b; //MIN
//       5'b01100: result = ($signed(a) > $signed(b)) ? a : b; //MAX
//       5'b01101: result = (a < b) ? a : b; //MINU
//       5'b01110: result = (a > b) ? a : b; //MAXU
//       5'b01111: result = (b[4:0] == 0) ? a:(a<<b[4:0]) | (a>>(32 - b[4:0])); //ROL
//       5'b10000: result = (b[4:0] == 0) ? a:(a>>b[4:0]) | (a<<(32 - b[4:0])); //ROR
//       5'b10001: result = ($signed(a) >= 0) ? a:-a; //ABS 

//       default: result = 32'bx;
//     endcase

//   assign zero = (result == 32'b0);
//   assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
  
// endmodule
module alu(input  logic [31:0] a, b,
           input  logic [4:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

    always_comb
      begin
        // Create a local variable for the shift amount to make the logic
        // explicit and avoid simulator warnings.
        logic [4:0] shamt = b[4:0];
        
        case (alucontrol)
          // Standard ALU operations (simplified for clarity and compatibility)
          5'b00000: result = a + b;
          5'b00001: result = a - b;
          5'b00010: result = a & b;
          5'b00011: result = a | b;
          5'b00100: result = a ^ b;
          5'b00101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // slt
          5'b00110: result = a << shamt;                                 // sll
          5'b00111: result = a >> shamt;                                 // srl

          // New RVX10 Operations
          5'b01000: result = a & ~b;
          5'b01001: result = a | ~b;
          5'b01010: result = ~(a ^ b);
          5'b01011: result = ($signed(a) < $signed(b)) ? a : b;
          5'b01100: result = ($signed(a) > $signed(b)) ? a : b;
          5'b01101: result = (a < b) ? a : b;
          5'b01110: result = (a > b) ? a : b;
          5'b01111: result = (shamt == 0) ? a : (a << shamt) | (a >> (32 - shamt));
          5'b10000: result = (shamt == 0) ? a : (a >> shamt) | (a << (32 - shamt));
          5'b10001: result = ($signed(a) >= 0) ? a : -a;
          
          default: result = 32'bx;
        endcase
      end
      
    assign zero = (result == 32'b0);
  
endmodule
