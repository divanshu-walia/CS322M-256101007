                                    FSM Sequence Detector Project
FSM Sequence Detector — CS322M Assignment

This project implements a Mealy-type Finite State Machine (FSM) in Verilog to detect the binary sequence `1011`. 
It includes source code, testbenches, simulation outputs, and waveform screenshots.

---

## 📁 Directory Contents

| File Name                          | Description                                  |
|-----------------------------------|----------------------------------------------|
| `seq_detect_mealy.v`              | Verilog module implementing the FSM logic    |
| `seq_detect_mealy_tb.v`           | Testbench for verifying FSM behavior         |
| `seq_detect_mealy_tb.vcd`         | VCD file generated from simulation           |
| `sim.vvp`                         | Compiled simulation output                   |
| `sim.out`                         | Console output from simulation run           |
| `waveform.png`                    | Waveform snapshot showing sequence detection |
| `output.png`                      | Output simulation on output stream           |
| `state diag.jpg`                  | FSM state diagram (visual reference)         |

---

## 🧠 FSM Design Overview

- **Type:** Mealy Machine  
- **Sequence Detected:** `1011`  
- **Overlapping Sequences:** Supported  
- **Clocking:** Positive edge-triggered  
- **Reset:** Asynchronous active-low

---

## 🛠️ How to Run

1. **Compile the design:**
   ```bash
   iverilog -o sim.vvp seq_detect_mealy_tb.v seq_detect_mealy.v

- Run the simulation:
  ```bash
   vvp sim.vvp
- View the waveform:
  ```bash
  gtkwave seq_detect_mealy_tb.vcd

## 🧪 Simulation & Waveform

### ✅ Output Waveform

![Waveform Screenshot](/fsm_assignments/problem1_seqdet/waveform.png)

> The FSM correctly asserts the output when the sequence `1011` is detected, even with overlapping inputs.

### 📊 State Diagram

![State Diagram](/fsm_assignments/problem1_seqdet/state%20diag.jpg)

> Visual representation of FSM states and transitions.

![Consol o/p](/fsm_assignments/problem1_seqdet/output.png)

✅ Features- Clean modular Verilog design
- Fully commented source and testbench
- Waveform-based verification
- Easy to extend for other sequences

Focused on practical digital design, waveform analysis, and simulation clarity.
