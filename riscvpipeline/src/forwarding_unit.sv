// src/forwarding_unit.sv
// Implements the forwarding logic to resolve data hazards.
// Selects ALU inputs from EX/MEM or MEM/WB if data hazards exist. 

module forwarding_unit(
    // Inputs: Register source/dest IDs from pipeline stages
    input  logic [4:0] rs1E,      // rs1 address in EX stage
    input  logic [4:0] rs2E,      // rs2 address in EX stage
    input  logic [4:0] rdM,       // Destination register in MEM stage
    input  logic [4:0] rdW,       // Destination register in WB stage
    
    // Inputs: Control signals from pipeline stages
    input  logic       RegWriteM, // RegWrite in MEM stage
    input  logic       RegWriteW, // RegWrite in WB stage
    
    // Outputs: Mux select signals for EX stage
    output logic [1:0] ForwardAE, // Select for ALU SrcA
    output logic [1:0] ForwardBE  // Select for ALU SrcB
);

  // Logic for ForwardAE (ALU Input A)
  // ---------------------------------
  always_comb begin
    // Priority 1: EX/MEM Hazard (Forward from MEM stage)
    // Check if MEM stage is writing to a register (rdM != x0)
    // and that register is the one EX stage wants to read (rdM == rs1E).
    if (RegWriteM && (rdM != 5'b0) && (rdM == rs1E))
      ForwardAE = 2'b10; // Forward ALUResultM

    // Priority 2: MEM/WB Hazard (Forward from WB stage)
    // Check if WB stage is writing (rdW != x0)
    // and that register is the one EX stage wants (rdW == rs1E).
    // This is lower priority, so we don't do it if an EX/MEM hazard exists.
    else if (RegWriteW && (rdW != 5'b0) && (rdW == rs1E))
      ForwardAE = 2'b01; // Forward ResultW
      
    // No Hazard
    else
      ForwardAE = 2'b00; // Use ReadData1E from Register File
  end

  // Logic for ForwardBE (ALU Input B)
  // ---------------------------------
  always_comb begin
    // Priority 1: EX/MEM Hazard (Forward from MEM stage)
    if (RegWriteM && (rdM != 5'b0) && (rdM == rs2E))
      ForwardBE = 2'b10; // Forward ALUResultM
      
    // Priority 2: MEM/WB Hazard (Forward from WB stage)
    else if (RegWriteW && (rdW != 5'b0) && (rdW == rs2E))
      ForwardBE = 2'b01; // Forward ResultW
      
    // No Hazard
    else
      ForwardBE = 2'b00; // Use ReadData2E from Register File
  end

endmodule