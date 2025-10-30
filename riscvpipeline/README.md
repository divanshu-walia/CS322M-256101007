# RVX10-P: A Five-Stage Pipelined RISC-V Core

This project is the implementation of a 5-stage, in-order pipelined RISC-V processor core. It is an evolution of a single-cycle core, partitioned into five stages (IF, ID, EX, MEM, WB) and equipped with a full hazard-handling system.

The core executes the base RV32I instruction set (`lw`, `sw`, R-type, I-type, `beq`, `jal`) as well as a custom 10-instruction extension, "RVX10".

## Core Features

* **5-Stage Pipelined Datapath:** Standard RISC-V five-stage pipeline (Instruction Fetch, Instruction Decode, Execute, Memory, Write-Back) for increased instruction throughput.
* **Full Hazard Handling:** Implements a complete hazard detection and resolution system:
    * **Data Hazard Resolution:** A `ForwardingUnit` resolves all ALU-to-ALU data hazards without stalling.
    * **Load-Use Hazard Stalling:** A `HazardDetectionUnit` detects load-use dependencies and inserts a one-cycle stall.
    * **Control Hazard Flushing:** Taken branches or jumps flush the incorrectly fetched instruction from the pipeline.
* **Custom ISA Extension (RVX10):** The ALU is extended to support 10 custom instructions for advanced arithmetic and bit manipulation.
* **Verification:** Passes a custom-designed test program (`rvx10_pipeline.txt`) that verifies all hazard conditions, custom instructions, and produces a known result (writing `25` to memory address `100`.

## Pipeline Stages



1.  **IF (Instruction Fetch):** Fetches the next instruction from `imem` using the Program Counter (PC).
2.  **ID (Instruction Decode):** Decodes the instruction, generates control signals, and reads source registers from the `regfile`.
3.  **EX (Execute):** Performs the operation in the ALU. All branch decisions and target addresses are calculated here. This stage is the source for data forwarding.
4.  **MEM (Memory Access):** Reads from (`lw`) or writes to (`sw`) the `dmem`. ALU results for non-memory operations pass through.
5.  **WB (Write Back):** Writes the final result (either from the ALU or `dmem`) back to the `regfile`.

## Hazard Handling

This processor correctly handles all data and control hazards:

* **Forwarding Unit:** Detects `EX/MEM` and `MEM/WB` data hazards. It provides the correct mux select signals to the ALU inputs to forward results directly from later stages, preventing stalls on back-to-back ALU operations.
* **Hazard Detection Unit:**
    * **Load-Use Stall:** When an instruction in the `ID` stage tries to read a register that an `lw` instruction in the `EX` stage is writing to, the unit stalls the `IF` and `ID` stages for one cycle and injects a `NOP` (bubble) into the `EX` stage.
    * **Branch Flush:** When a branch is taken (detected in the `EX` stage), the unit sends a flush signal to the `IF/ID` register to replace the (incorrectly) fetched instruction with a `NOP`.

## RVX10 Custom ISA

The core supports 10 custom R-type instructions, all of which use the `funct7 = 7'b0001011` opcode:

* `ANDN`
* `ORN`
* `XNOR`
* `MIN`
* `MAX`
* `MINU`
* `MAXU`
* `ROL`
* `ROR`
* `ABS`

## Repository Structure
```bash
/riscvpipeline
   │
   ├───src
   │      ├─── controller.sv
   │      ├─── datapath.sv
   │      ├─── forwarding_unit.sv
   │      ├─── hazard_unit.sv
   │      ├─── riscvpipeline.sv
   │
   ├───tb
   │      ├─── tb_pipeline.sv
   │
   ├───tests
   │      ├───rvx10_pipeline.txt
   │
   │
   ├───outputs
   │      ├─── 1.1.jpg
   │      ├─── 1.2.jpg
   │      ├─── 2.jpg
   │      ├─── 3.jpg
   │      ├─── 4.jpg
   │      ├─── A.jpg
   │      ├─── AAA.jpg
   │      ├─── B.jpg
   │      ├─── C.jpg
   │      ├─── Simulation Successful.jpg
   │
   ├─── pipeline.vcd
   │
   ├─── sim
```

## How to Run

This project uses [Icarus Verilog](https://github.com/steveicarus/iverilog) for simulation and [GTKWave](http://gtkwave.sourceforge.net/) for waveform viewing.

1.  **Compile the design:**
    ```sh
    iverilog -g2012 -o sim -I ./src ./tb/tb_pipeline.sv ./src/riscvpipeline.sv
    ```

2.  **Run the simulation:**
    ```sh
    vvp sim
    ```

3.  **Check the output:**
    If successful, the console will print **`Simulation succeeded`**.

    ```
    Simulation succeeded
    .\tb\tb_pipeline.sv:33: $stop called at 95 (1s)
    ** VVP Stop(0) **
    ** Flushing output streams.
    ** Current simulation time is 95 ticks.
    ```

4.  **Generate and view waveforms (VCD):**
    * Generates a `pipeline.vcd` file, which can be opened with GTKWave.
    ```sh
    gtkwave pipeline.vcd
    ```

## Info

This project was developed under the guidance of **Dr. Satyajit Das** as part of the course:
**Digital Logic and Computer Architecture (CS 553)**.  

**Divanshu Walia**  
**IIT GUWAHATI**
