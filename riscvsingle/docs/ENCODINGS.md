# RVX10 Instruction Encodings (CUSTOM-0)

[cite_start]All RVX10 instructions use the **R-type** format with a custom **opcode = 0x0B (7'b0001011)**[cite: 159]. [cite_start]The specific operation is selected by the `funct7` and `funct3` fields[cite: 181].

| Field  | Bits  | Purpose |
| :---   | :---  | :--- |
| funct7 | 31:25 | Operation-specific modifier |
| rs2    | 24:20 | [cite_start]Second source register index (ignored for ABS, set to x0) [cite: 160, 175] |
| rs1    | 19:15 | First source register index |
| funct3 | 14:12 | Operation-specific modifier |
| rd     | 11:7  | [cite_start]Destination register index (must not be x0) [cite: 178] |
| opcode | 6:0   | 0001011 (0x0B) |

---

## RVX10 Instruction Set Table

| Instr | funct7 (bin) | funct3 (bin) |
| :---  | :--- | :--- |
| ANDN  | 0000000 | 000 |
| ORN   | 0000000 | 001 |
| XNOR  | 0000000 | 010 |
| MIN   | 0000001 | 000 |
| MAX   | 0000001 | 001 |
| MINU  | 0000001 | 010 |
| MAXU  | 0000001 | 011 |
| ROL   | 0000010 | 000 |
| ROR   | 0000010 | 001 |
| ABS   | 0000011 | 000 |

---

## Worked Encoding Example: ANDN x5, x6, x7

**Instruction**: `ANDN x5, x6, x7`  ($rd=x5$, $rs1=x6$, $rs2=x7$)
**Operation**: $rd = rs1 \& \sim rs2$
**Binary Opcode**: 0001011
**funct3**: 000
**funct7**: 0000000

| Field  | Value (Decimal)           | Value (Binary) | Shifted Hex Value |
| :---   | :---                      | :---           | :--- |
| funct7 | 0                         | 0000000        | $0 \ll 25 \rightarrow 0\times00000000$ |
| rs2    | $x7 \rightarrow 7$        | 00111          | $7 \ll 20 \rightarrow 0\times00700000$ |
| rs1    | $x6 \rightarrow 6$        | 00110          | $6 \ll 15 \rightarrow 0\times00030000$ |
| funct3 | 0                         | 000            | $0 \ll 12 \rightarrow 0\times00000000$ |
| rd     | $x5 \rightarrow 5$        | 00101          | $5 \ll 7 \rightarrow 0\times00000280$ |
| opcode | 0x0B                      | 0001011        | $0\times0000000B$ |
| **Total Instruction (32-bit Hex)** |                | | $\mathbf{0\times0073028B}$ |