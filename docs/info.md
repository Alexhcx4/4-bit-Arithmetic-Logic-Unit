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

## How to test

1. **Simulation in Vivado**: Add `ALUchip.v` (design source) and `tb_tt_um_ALUejemplo.v` or `ALU_tb_dirigido.v` (simulation sources), set the desired testbench as top, and run **Behavioral Simulation**.
2. **Apply stimulus**: Set `ui_in[3:0]` (`A`), `ui_in[7:4]` (`B`), and `uio_in[4:0]` (`FS`). Because the core ALU is combinational, `uo_out` updates immediately for each input combination.
3. **Verify outputs**: Read `uo_out[3:0]` for the 4-bit result and `uo_out[7:4]` for `{Z, N, C, V}`, confirming zero mismatches in the simulation log or console.

## External hardware

No external hardware is required. For standalone simulation or bench testing, standard digital switches/DIP switches can drive `ui_in` and `uio_in`, and LEDs or a logic analyzer can observe `uo_out`.
