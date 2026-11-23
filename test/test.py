# SPDX-FileCopyrightText: © 2026 TECNM-ITTehuacán
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def golden_alu(a_val: int, b_val: int, fs_val: int):
    a = a_val & 0xF
    b = b_val & 0xF
    fs = fs_val & 0x1F

    temp = 0
    res = 0
    c = 0
    v = 0

    if fs == 0b00000:
        res = a
    elif fs == 0b00001:
        temp = a + 1
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        v = ((a >> 3) & 0x1) & (~((res >> 3) & 0x1) & 0x1)
    elif fs == 0b00010:
        temp = a + b
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        a3, b3, r3 = (a >> 3) & 1, (b >> 3) & 1, (res >> 3) & 1
        v = (a3 & b3 & ~r3) | ((~a3 & 1) & (~b3 & 1) & r3)
    elif fs == 0b00011:
        temp = a + b + 1
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        a3, b3, r3 = (a >> 3) & 1, (b >> 3) & 1, (res >> 3) & 1
        v = (a3 & b3 & ~r3) | ((~a3 & 1) & (~b3 & 1) & r3)
    elif fs == 0b00100:
        temp = a + ((~b) & 0xF)
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        a3, b3, r3 = (a >> 3) & 1, (b >> 3) & 1, (res >> 3) & 1
        v = (a3 & (~b3 & 1) & (~r3 & 1)) | ((~a3 & 1) & b3 & r3)
    elif fs == 0b00101:
        temp = a + ((~b) & 0xF) + 1
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        a3, b3, r3 = (a >> 3) & 1, (b >> 3) & 1, (res >> 3) & 1
        v = (a3 & (~b3 & 1) & (~r3 & 1)) | ((~a3 & 1) & b3 & r3)
    elif fs == 0b00110:
        temp = (a - 1) & 0x1F
        res = temp & 0xF
        c = (temp >> 4) & 0x1
        v = 1 if a == 0b1000 else 0
    elif fs == 0b00111:
        res = b
    elif fs == 0b01000:
        res = a & b
    elif fs == 0b01010:
        res = a | b
    elif fs == 0b01100:
        res = a ^ b
    elif fs == 0b01110:
        res = (~a) & 0xF
    elif fs == 0b10000:
        res = (~b) & 0xF
    elif fs == 0b10100:
        res = (b >> 1) & 0xF
        c = b & 0x1
    elif fs == 0b11000:
        res = (b << 1) & 0xF
        c = (b >> 3) & 0x1
    else:
        res = 0
        c = 0
        v = 0

    n = (res >> 3) & 0x1
    z = 1 if res == 0 else 0
    exp_uo = (z << 7) | (n << 6) | (c << 5) | (v << 4) | res
    return exp_uo, res, v, c, n, z


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test ALU behavior")

    # Casos dirigidos clave (A, B, FS)
    test_vectors = [
        (0x5, 0x3, 0b00000),  # Transfer A
        (0x7, 0x4, 0b00001),  # INC A (7 + 1 = 8 -> V=1, N=1)
        (0x3, 0x1, 0b00010),  # A + B
        (0xF, 0x1, 0b00010),  # A + B con acarreo (15 + 1 = 0 -> C=1, Z=1)
        (0x6, 0x3, 0b00011),  # A + B + 1
        (0xF, 0x1, 0b00100),  # A + ~B
        (0x5, 0x5, 0b00101),  # A - B = 0 (Z=1)
        (0x8, 0x0, 0b00110),  # DEC(1000) -> V=1
        (0x3, 0xA, 0b00111),  # Transfer B
        (0xC, 0x9, 0b01000),  # A AND B
        (0xC, 0x9, 0b01010),  # A OR B
        (0xC, 0x9, 0b01100),  # A XOR B
        (0xC, 0x9, 0b01110),  # NOT A
        (0xC, 0x9, 0b10000),  # NOT B
        (0xC, 0x9, 0b10100),  # SHR B (C=1)
        (0xC, 0x9, 0b11000),  # SHL B (C=1)
        (0xC, 0x9, 0b11111),  # Default -> Result=0, Z=1
    ]

    for a_val, b_val, fs_val in test_vectors:
        dut.ui_in.value = ((b_val & 0xF) << 4) | (a_val & 0xF)
        dut.uio_in.value = fs_val & 0x1F
        await ClockCycles(dut.clk, 1)

        exp_uo, res, v, c, n, z = golden_alu(a_val, b_val, fs_val)
        got_uo = int(dut.uo_out.value)
        assert got_uo == exp_uo, (
            f"FS={fs_val:05b} A={a_val:04b} B={b_val:04b}: "
            f"got uo_out=0x{got_uo:02x}, expected 0x{exp_uo:02x} "
            f"(res=0x{res:x}, V={v}, C={c}, N={n}, Z={z})"
        )

    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0
