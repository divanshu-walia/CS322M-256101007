# CS322M Assignment: RVX10 Processor Extension

This repository contains the solution for the RVX10 assignment, which extends a base single-cycle RV32I processor core with 10 custom arithmetic and logical instructions.

## 1. Project Overview

The goal of this assignment was to implement 10 new single-cycle instructions (RVX10) using the reserved CUSTOM−0 opcode (0×0B). This involved co-designing the Instruction Set Architecture (ISA) with the Register-Transfer Level (RTL) logic within the constraints of a single-cycle datapath (no architectural state changes beyond registers).

RVX10 Implemented Instructions

Category	Instructions	Example
Logic	ANDN, ORN, XNOR	rd=rs1&∼rs2
Compare	MIN, MAX, MINU, MAXU	rd=(rs1<rs2)?rs1:rs2
Shift/Arith	ROL, ROR, ABS	rd=(rs1≪s)∣(rs1≫(32−s))


## 2. Build and Run Instructions

This project uses the Icarus Verilog (iverilog) / vvp toolchain for simulation.

Build the simulation executable:
Compile the modified processor core into an executable.

Bash

    iverilog -g2012 -o sim src/riscvsingle.sv

(Note: The testbench expects to load the test file named riscvtest.txt from the tests/ directory as configured in the imem module.)

Run the simulation:
Execute the compiled binary.

Bash

     vvp sim
    
## 3. Success Criteria

The simulation is considered successful if the test program executes all RVX10 operations and correctly sets the final architectural state.

Primary Success Condition

The testbench is configured to watch for a specific data memory write operation.

    Expected Output: Simulation succeeded

    Trigger Condition: Storing the value 25 (0×19) to memory address 100 (0×64).

Secondary Verification (Checksum)

The test program uses register x28 as a checksum accumulator to confirm all 10 operations ran correctly.

    Final x28 Value: 55 (0×37)
## 4. Output
![Output](riscvsingle/output.png)
