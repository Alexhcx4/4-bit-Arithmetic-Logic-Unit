![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

<!---

<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a 4-bit combinational Arithmetic Logic Unit (`alu_4bit`) wrapped inside the `tt_um_ALUejemplo` interface (`ui_in`, `uo_out`, `uio_in`). It takes two 4-bit operands (`A_Data` and `B_Data`) and a 5-bit function selector (`FS`) to produce a 4-bit result (`Result`) along with four status flags (`V`, `C`, `N`, and `Z`).

### Pin mapping
* **Inputs (`ui_in`)**: `ui_in[3:0]` (`A0`–`A3`) provides operand `A`, and `ui_in[7:4]` (`B0`–`B3`) provides operand `B`.
* **Function select (`uio_in`)**: `uio_in[4:0]` (`FS0`–`FS4`) selects the ALU operation. Bidirectional pins are configured as inputs (`uio_oe = 8'h00`, `uio_out = 8'h00`).
* **Outputs (`uo_out`)**: `uo_out[3:0]` (`F0`–`F3`) outputs `Result`, while `uo_out[7:4]` outputs `{Z, N, C, V}` (`uo_out[4]` = `V`, `uo_out[5]` = `C`, `uo_out[6]` = `N`, `uo_out[7]` = `Z`).

### Operations and flags
* **Arithmetic**: Transfer `A` (`00000`), increment `A + 1` (`00001`), add `A + B` (`00010`), add with carry-in `A + B + 1` (`00011`), `A + ~B` (`00100`), subtract `A - B` (`00101`), decrement `A - 1` (`00110`), and transfer `B` (`00111`).
* **Logic and shifts**: `A AND B` (`01000`), `A OR B` (`01010`), `A XOR B` (`01100`), `NOT A` (`01110`), `NOT B` (`10000`), logical shift right `B >> 1` (`10100`), and logical shift left `B << 1` (`11000`). Undefined `FS` codes default to `Result = 4'b0000` and `C = 0`.
* **Flags**: `V` indicates signed two's-complement overflow on supported arithmetic operations (including `A == 4'b1000` on `DEC A`), `C` captures carry-out or shifted-out bits, `N` reflects `Result[3]`, and `Z` asserts `1` when `Result == 4'b0000`.

### Function select (`FS`) specification

| `FS` (`uio_in[4:0]`) | Operation | `Result` (`uo_out[3:0]`) |
| :--- | :--- | :--- |
| `00000` | Transfer `A` | `A` |
| `00001` | Increment `A` | `A + 1` |
| `00010` | Add `A + B` | `A + B` |
| `00011` | Add with carry-in | `A + B + 1` |
| `00100` | Add bitwise NOT `B` | `A + ~B` |
| `00101` | Subtract `A - B` | `A + ~B + 1` |
| `00110` | Decrement `A` | `A - 1` |
| `00111` | Transfer `B` | `B` |
| `01000` | Bitwise AND | `A & B` |
| `01010` | Bitwise OR | `A \| B` |
| `01100` | Bitwise XOR | `A ^ B` |
| `01110` | Bitwise NOT `A` | `~A` |
| `10000` | Bitwise NOT `B` | `~B` |
| `10100` | Shift right `B` | `B >> 1` |
| `11000` | Shift left `B` | `B << 1` |
| Any other (`default`) | Undefined / Reserved | `4'b0000` |

## How to test

1. **Power and reset setup**: Supply regulated power (`VDD` and `GND`) to the board/chip, assert `rst_n` low (`0`) during initial power-up and then pull `rst_n` high (`1`), and keep `ena` high (`1`).
2. **Drive inputs (`ui_in` and `uio_in`)**: Connect DIP switches, pushbuttons, or a microcontroller/pattern generator to drive `ui_in[3:0]` (`A0`–`A3`), `ui_in[7:4]` (`B0`–`B3`), and `uio_in[4:0]` (`FS0`–`FS4`). Leave `uio[7:5]` unconnected or at a known logic level (`uio_oe = 8'h00`).
3. **Observe outputs (`uo_out`)**: Connect LEDs (with current-limiting resistors), a logic analyzer, or digital inputs on a microcontroller to `uo_out[3:0]` (`F0`–`F3`) to read `Result`, and to `uo_out[7:4]` to read `V` (`uo_out[4]`), `C` (`uo_out[5]`), `N` (`uo_out[6]`), and `Z` (`uo_out[7]`).
4. **Verify operations and flags**: Step through desired `FS` opcodes and `A` / `B` input pairs (such as `00010` for `A + B`, `00101` for `A - B`, `10100` for `SHR B`, and `11111` for default `0000`), checking that `F0`–`F3` and the `V`, `C`, `N`, `Z` indicators match the expected values.

## External hardware

No specialized external hardware is strictly required to run the ALU, as it is self-contained within the design pins. For physical bench testing and verification, you can use:
* **Input drivers**: 13 digital switches or DIP switches (4 for `A0`–`A3`, 4 for `B0`–`B3`, and 5 for `FS0`–`FS4`), or digital output pins from a microcontroller/FPGA board to automate test vectors.
* **Output indicators / instrumentation**: 8 LEDs (with series current-limiting resistors) for `F0`–`F3` and `V`, `C`, `N`, `Z`, or a logic analyzer / digital acquisition setup to capture and verify states.
