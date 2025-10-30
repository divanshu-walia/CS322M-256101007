// src/hazard_unit.sv
// Detects load-use hazards and control hazards, generating stall/flush signals.

module hazard_unit(
    // Inputs for Load-Use Detection
    input  logic [4:0] rs1D,      // rs1 of instr in ID stage
    input  logic [4:0] rs2D,      // rs2 of instr in ID stage
    input  logic [4:0] rdE,       // Destination register of instr in EX stage
    input  logic       MemReadE,  // Is the instruction in EX a load?
    
    // Input for Control Hazard Detection
    input  logic       PCSrcE,    // Is a branch being taken or a jump occurring in EX?
    
    // Outputs: Stall and Flush control signals
    output logic       StallF,    // Stalls the PC
    output logic       StallD,    // Stalls the IF/ID register
    output logic       FlushE,    // Flushes the ID/EX register (injects NOP)
    output logic       FlushD     // Flushes the IF/ID register (for branches)
);

  // Load-Use Hazard Detection Logic
  // A hazard occurs if the instruction in the EX stage is a load (MemReadE),
  // and its destination register (rdE) is one of the source registers (rs1D or rs2D)
  // for the instruction currently in the ID stage.
  logic load_use_hazard;
  assign load_use_hazard = MemReadE && (rdE != 5'b0) && ((rdE == rs1D) || (rdE == rs2D));
  
  // Stall signals are asserted when a load-use hazard is detected.
  assign StallF = load_use_hazard; // Stop the PC from updating
  assign StallD = load_use_hazard; // Stop the IF/ID register from updating
  
  // When stalling, we must flush the instruction that has just reached the EX stage.
  // This replaces it with a NOP (bubble) while the pipeline waits.
  assign FlushE = load_use_hazard;

  // Control Hazard Detection Logic
  // If a branch is taken or a jump occurs (PCSrcE is high), the instruction
  // that was fetched right after it (now in the ID stage) is incorrect and must be flushed.
  assign FlushD = PCSrcE;
  
endmodule