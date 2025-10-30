// src/riscvpipeline.sv
// The main 5-stage pipelined processor module.

`include "controller.sv"
`include "datapath.sv"
`include "hazard_unit.sv"
`include "forwarding_unit.sv"

module riscvpipeline(
    input  logic        clk, reset,
    
    // Instruction Memory Interface (IF)
    output logic [31:0] PC,          // PC to imem
    input  logic [31:0] Instr,       // Instr from imem
    
    // Data Memory Interface (MEM)
    output logic        MemWrite,    // MemWrite to dmem
    output logic [31:0] DataAdr,     // Address to dmem
    output logic [31:0] WriteData,   // WriteData to dmem
    input  logic [31:0] ReadData     // ReadData from dmem
);

  // NOP instruction (addi x0, x0, 0)
  localparam NOP = 32'h00000013;

  // Wires for Hazard Unit signals
  logic       StallF, StallD, FlushD, FlushE;
  logic [1:0] ForwardAE, ForwardBE;
  logic       PCSrcE; // From EX stage, controls PC Mux

  //-----------------------------------------------------------------
  // IF: Instruction Fetch Stage
  //-----------------------------------------------------------------
  logic [31:0] PCF, PCNextF, PCPlus4F;

  // PC Register
  always_ff @(posedge clk, posedge reset)
    if (reset) PCF <= 32'd0;
    else if (!StallF) PCF <= PCNextF;
    // if StallF is high, PCF is not updated.
  
  // Adder for PC + 4
  adder pcadd4 (
    .a(PCF),
    .b(32'd4),
    .y(PCPlus4F)
  );
  
  // PC Mux (Selects PC+4 or Branch/JAL Target)
  // Note: PCTargetE comes from the EX stage
  logic [31:0] PCTargetE; 
  mux2 #(32) pcmux (
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNextF)
  );

  // Output to imem
  assign PC = PCF;

  //-----------------------------------------------------------------
  // IF/ID Pipeline Register
  //-----------------------------------------------------------------
  logic [31:0] PCD, InstrD, PCPlus4D;

  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      PCD      <= 32'd0;
      InstrD   <= NOP;
      PCPlus4D <= 32'd0;
    end else if (FlushD) begin
      PCD      <= 32'd0;
      InstrD   <= NOP; // Flush instruction
      PCPlus4D <= 32'd0;
    end else if (!StallD) begin
      PCD      <= PCF;
      InstrD   <= Instr; // Load instruction from IF
      PCPlus4D <= PCPlus4F;
    end
    // if StallD is high, register values are frozen.

  //-----------------------------------------------------------------
  // ID: Instruction Decode / Register Read Stage
  //-----------------------------------------------------------------
  logic [1:0] ResultSrcD, ImmSrcD, ALUOpD;
  logic       MemWriteD, ALUSrcD, RegWriteD, BranchD, JumpD;
  logic [4:0] ALUControlD;
  logic [31:0] ReadData1D, ReadData2D, ImmExtD;
  logic [4:0] rs1D, rs2D, rdD;
  
  assign rs1D = InstrD[19:15];
  assign rs2D = InstrD[24:20];
  assign rdD  = InstrD[11:7];

  // Controller
  // **MODIFIED**: Controller instance now has a Branch output.
  controller c (
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7(InstrD[31:25]),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .ImmSrc(ImmSrcD),
    .ALUControl(ALUControlD),
    .Branch(BranchD) // New output from controller
  );

  // Register File
  // Reads are in ID (rs1D, rs2D)
  // Write is in WB (RegWriteW, rdW, ResultW)
  logic [31:0] ResultW;
  logic [4:0]  rdW;
  logic        RegWriteW;
  
  regfile rf (
    .clk(clk),
    .we3(RegWriteW),
    .a1(rs1D),
    .a2(rs2D),
    .a3(rdW),
    .wd3(ResultW),
    .rd1(ReadData1D),
    .rd2(ReadData2D)
  );

  // Immediate Extender
  extend ext (
    .instr(InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ImmExtD)
  );

  //-----------------------------------------------------------------
  // ID/EX Pipeline Register
  //-----------------------------------------------------------------
  logic [1:0] ResultSrcE, ALUOpE;
  logic       MemWriteE, ALUSrcE, RegWriteE, BranchE, JumpE;
  logic [4:0] ALUControlE;
  logic [31:0] PCE, ReadData1E, ReadData2E, ImmExtE, PCPlus4E;
  logic [4:0] rs1E, rs2E, rdE;

  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      {ResultSrcE, MemWriteE, ALUSrcE, RegWriteE, BranchE, JumpE} <= 0;
      ALUControlE <= 0;
      {PCE, ReadData1E, ReadData2E, ImmExtE, PCPlus4E} <= 0;
      {rs1E, rs2E, rdE} <= 0;
    end else if (FlushE) begin
      {ResultSrcE, MemWriteE, ALUSrcE, RegWriteE, BranchE, JumpE} <= 0;
      ALUControlE <= 0; // Flush control signals
      {PCE, ReadData1E, ReadData2E, ImmExtE, PCPlus4E} <= 0;
      {rs1E, rs2E, rdE} <= 0;
    end else begin  // <-- This line was changed
      {ResultSrcE, MemWriteE, ALUSrcE, RegWriteE, BranchE, JumpE} <= {ResultSrcD, MemWriteD, ALUSrcD, RegWriteD, BranchD, JumpD};
      ALUControlE <= ALUControlD;
      {PCE, ReadData1E, ReadData2E, ImmExtE, PCPlus4E} <= {PCD, ReadData1D, ReadData2D, ImmExtD, PCPlus4D};
      {rs1E, rs2E, rdE} <= {rs1D, rs2D, rdD};
    end
    // if StallE is high, register values are frozen.

  //-----------------------------------------------------------------
  // EX: Execute Stage
  //-----------------------------------------------------------------
  logic [31:0] SrcAE, SrcBE, ALUResultE, WriteDataE;
  logic        ZeroE;

  // Branch Target Adder
  adder pcaddbranch (
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );
  
  // Forwarding Mux for ALU SrcA
  mux3 #(32) fwdAmux (
    .d0(ReadData1E), // 00: From RegFile
    .d1(ResultW),    // 01: From WB Stage
    .d2(ALUResultM), // 10: From MEM Stage
    .s(ForwardAE),
    .y(SrcAE)
  );

  // Forwarding Mux for ALU SrcB
  mux3 #(32) fwdBmux (
    .d0(ReadData2E), // 00: From RegFile
    .d1(ResultW),    // 01: From WB Stage
    .d2(ALUResultM), // 10: From MEM Stage
    .s(ForwardBE),
    .y(SrcBE)
  );

  // ALU SrcB Mux (Reg vs Imm)
  logic [31:0] ALUSrcB;
  mux2 #(32) srcbmux (
    .d0(SrcBE),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(ALUSrcB)
  );

  // Main ALU
  alu alu (
    .a(SrcAE),
    .b(ALUSrcB),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  );

  // Branch logic (moved from controller)
  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  // Data to be written to memory (for sw)
  assign WriteDataE = SrcBE; 
  
  //-----------------------------------------------------------------
  // EX/MEM Pipeline Register
  //-----------------------------------------------------------------
  logic [1:0] ResultSrcM;
  logic       MemWriteM, RegWriteM;
  logic [31:0] ALUResultM, WriteDataM, PCPlus4M;
  logic [4:0]  rdM;

  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      {ResultSrcM, MemWriteM, RegWriteM} <= 0;
      {ALUResultM, WriteDataM, PCPlus4M} <= 0;
      rdM <= 0;
    end else begin
      // MEM stage never stalls
      {ResultSrcM, MemWriteM, RegWriteM} <= {ResultSrcE, MemWriteE, RegWriteE};
      {ALUResultM, WriteDataM, PCPlus4M} <= {ALUResultE, WriteDataE, PCPlus4E};
      rdM <= rdE;
    end

  //-----------------------------------------------------------------
  // MEM: Memory Access Stage
  //-----------------------------------------------------------------
  // Connect to dmem ports
  assign DataAdr  = ALUResultM; // Address for lw/sw
  assign WriteData = WriteDataM; // Data for sw
  assign MemWrite = MemWriteM;  // Write enable for sw
  // ReadData comes from dmem port

  //-----------------------------------------------------------------
  // MEM/WB Pipeline Register
  //-----------------------------------------------------------------
  logic [1:0] ResultSrcW;
  logic [31:0] ReadDataW, ALUResultW, PCPlus4W;

  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      ResultSrcW <= 0;
      RegWriteW  <= 0;
      {ReadDataW, ALUResultW, PCPlus4W} <= 0;
      rdW <= 0;
    end else begin
      // WB stage never stalls
      ResultSrcW <= ResultSrcM;
      RegWriteW  <= RegWriteM;
      {ReadDataW, ALUResultW, PCPlus4W} <= {ReadData, ALUResultM, PCPlus4M};
      rdW <= rdM;
    end

  //-----------------------------------------------------------------
  // WB: Write Back Stage
  //-----------------------------------------------------------------
  
  // Result Mux (ALU vs MemData vs PC+4)
  mux3 #(32) resultmux (
    .d0(ALUResultW), // 00: ALU result
    .d1(ReadDataW),  // 01: Memory read data
    .d2(PCPlus4W),   // 10: PC+4 (for JAL)
    .s(ResultSrcW),
    .y(ResultW)
  );
  
  // Write to regfile happens in ID stage, but is controlled 
  // by signals from this stage (RegWriteW, rdW, ResultW)


  
//-----------------------------------------------------------------
// Hazard and Forwarding Units
//-----------------------------------------------------------------
  
  // Forwarding Unit
  
  
  forwarding_unit fwd_unit (
    // Inputs: Register destinations in EX/MEM and MEM/WB
    .rs1E(rs1E),
    .rs2E(rs2E),
    .rdM(rdM),
    .rdW(rdW),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    
    // Outputs: Mux select signals for EX stage
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE)
  );

//Hazard Detection Unit
 

  logic MemReadE; // This signal identifies an 'lw' instruction
  assign MemReadE = (ResultSrcE == 2'b01); // True when result comes from memory

  hazard_unit hzd_unit (
    // Inputs: Load-use detection
    .rs1D(rs1D),
    .rs2D(rs2D),
    .rdE(rdE),
    .MemReadE(MemReadE),
    
    // Inputs: Branch detection
    .PCSrcE(PCSrcE),
    
    // Outputs: Stall and Flush signals
    .StallF(StallF),
    .StallD(StallD),
    .FlushE(FlushE),
    .FlushD(FlushD)
  );


    // --- Performance Counters (Optional Bonus) ---
  reg [31:0] cycle_count, instr_retired;

  // Initialize counters
  initial begin
    cycle_count = 0;
    instr_retired = 0;
  end

  // Cycle counter: increments every clock cycle
  always_ff @(posedge clk, posedge reset) begin
    if (reset)
      cycle_count <= 0;
    else
      cycle_count <= cycle_count + 1;
  end

  // Instruction retired counter: increments when an instruction
  // successfully reaches the Write-Back stage and performs a write.
  // This signal (RegWriteW) is already '0' for NOPs/bubbles.
  always_ff @(posedge clk, posedge reset) begin
    if (reset)
      instr_retired <= 0;
    else if (RegWriteW) // From WB stage
      instr_retired <= instr_retired + 1;
  end
  // --- End of Performance Counters ---


endmodule