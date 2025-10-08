# RVX10 Test Plan

## Self-Checking Strategy

1.  Initialize Checksum Register (**x28**) to 0.
2.  For each of the 10 RVX10 operations, a test is performed using defined inputs.
3.  The result of the operation is added to the Checksum Register (x28).
4.  The final value of x28 is compared against a pre-calculated **Target Checksum**.
5.  [cite_start]The final step is to store the value **25** to memory address **100**.

## Test Case Definitions

| Instr    | rs1 (Hex)  | rs2 (Hex)  | Semantics Check                                  | Expected rd (Hex)     | Checksum Add (Dec) |
| :---     | :---       | :---       | :---                                             | :---                  | :---               |
| **ANDN** | 0xF0F0A5A5 | 0x0F0FFFFF | F0F0A5A5 & ~0F0FFFFF                             | 0xF0F00000            | +1                 |
| **ORN**  | 0x00000001 | 0xFFFFFFFF | 1                                                | ~FFFFFFFF | 0x00000001| +2                 |
| **XNOR** | 0xAAAAAAAA | 0x55555555 | ~(A^5) = ~(F) = 0                                | 0x00000000            | +3                 |
| **MIN**  | 0x80000001 | 0x00000005 | Signed: -INT_MAX vs 5                            | 0x80000001            | +4                 |
| **MAX**  | 0x80000000 | 0x7FFFFFFF | Signed: INT_MIN vs INT_MAX                       | 0x7FFFFFFF            | +5                 |
| **MINU** | 0xFFFFFFFE | 0x00000001 | Unsigned: Large vs Small                         | 0x00000001            | +6                 |
| **MAXU** | 0xFFFFFFFE | 0x00000001 | Unsigned: Large vs Small                         | 0xFFFFFFFE            | +7                 |
| **ROL**  | 0x80000001 | 0x00000003 | ROL by 3                                         | 0x00000008            | +8                 |
| **ROR**  | 0x0000000F | 0x00000004 | ROR by 4                                         | 0xF0000000            | +9                 |
| **ABS**  | 0x80000000 | 0x00000000 | [cite_start]ABS(INT_MIN) (x0 is rs2) [cite: 177] | 0x80000000            | +10                |

**Target Checksum**: $\sum (1 \dots 10) = 55$

## Expected Final State

1.  `x28` (Checksum Register) $= 0\times00000037$ (55 decimal).
2.  [cite_start]Memory address $\mathbf{100}$ (0x64) contains the value $\mathbf{25}$ (0x19).