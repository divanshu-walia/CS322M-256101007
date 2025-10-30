// tb/tb_pipeline.sv
// Testbench and top-level wrapper

module testbench();
  logic        clk;
  logic        reset;
  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  // This is the top-level wrapper, NOT the processor itself
  top dut(clk, reset, WriteData, DataAdr, MemWrite);

  // initialize test
  initial
    begin

        $dumpfile("pipeline.vcd");
        $dumpvars(0, dut);

      reset <= 1; # 22;
      reset <= 0;
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


    // This block runs at the end of the simulation
  final begin
    $display("---------------------------------");
    $display("--- Performance Counters ---");
    $display("Total Cycles:         %0d", dut.rvpipe.cycle_count);
    $display("Instructions Retired: %0d", dut.rvpipe.instr_retired);
    
    // Check for division by zero
    if (dut.rvpipe.instr_retired > 0)
      $display("Average CPI:          %f", $itor(dut.rvpipe.cycle_count) / $itor(dut.rvpipe.instr_retired));
    else
      $display("Average CPI:          N/A (0 instructions retired)");
    $display("---------------------------------");
  end

  
endmodule

// This module is the wrapper that connects the processor
// to the instruction and data memories.
module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);
           
  logic [31:0] PC, Instr, ReadData;
  
  // Instantiate processor and memories
  // *** This is the key change ***
  // We are instantiating the new pipelined core as required 
  riscvpipeline rvpipe(clk, reset, PC, Instr, MemWrite, DataAdr, 
                       WriteData, ReadData);
                       
  imem imem(PC, Instr); // imem connects to IF stage
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData); // dmem connects to MEM stage
endmodule

// Instruction Memory
module imem(input  logic [31:0] a,
            output logic [31:0] rd);
  logic [31:0] RAM[63:0];

  initial
      $readmemh("tests/rvx10_pipeline.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned
endmodule

// Data Memory
module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);
  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule