/*
 * Copyright (c) 2026 TECNM-ITTehuacán
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_ALUejemplo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Mapeo de entradas hacia la ALU de 4 bits
  wire [4:0] fs_sel = {ui_in[4], uio_in[7:4]};
  wire [3:0] a_data = ui_in[3:0];
  wire [3:0] b_data = uio_in[3:0];

  // Salidas internas de la ALU
  wire [3:0] alu_result;
  wire       flag_v;
  wire       flag_c;
  wire       flag_n;
  wire       flag_z;

  alu_4bit u_alu (
      .FS     (fs_sel),
      .A_Data (a_data),
      .B_Data (b_data),
      .Result (alu_result),
      .V      (flag_v),
      .C      (flag_c),
      .N      (flag_n),
      .Z      (flag_z)
  );

  // Salidas dedicadas y pines bidireccionales no usados como salida
  assign uo_out  = {flag_z, flag_n, flag_c, flag_v, alu_result};
  assign uio_out = 8'b0000_0000;
  assign uio_oe  = 8'b0000_0000;

  // Evitar advertencias por señales sin usar en este diseño combinacional
  wire _unused = &{ena, clk, rst_n, ui_in[7:5], 1'b0};

endmodule


`timescale 1ns / 1ps

module alu_4bit (
    input  wire [4:0] FS,
    input  wire [3:0] A_Data,
    input  wire [3:0] B_Data,
    output reg  [3:0] Result,
    output reg        V,
    output reg        C,
    output reg        N,
    output reg        Z
);

  reg [4:0] temp_v;

  always @(*) begin
    // Valores por defecto para evitar latches
    Result = 4'b0000;
    temp_v = 5'b00000;
    C      = 1'b0;
    V      = 1'b0;

    case (FS)
      // Transfer A
      5'b00000: begin
        Result = A_Data;
      end

      // INCREMENT A
      5'b00001: begin
        temp_v = {1'b0, A_Data} + 5'd1;
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // A + B
      5'b00010: begin
        temp_v = {1'b0, A_Data} + {1'b0, B_Data};
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // A + B + 1
      5'b00011: begin
        temp_v = {1'b0, A_Data} + {1'b0, B_Data} + 5'd1;
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // A + not B
      5'b00100: begin
        temp_v = {1'b0, A_Data} + {1'b0, ~B_Data};
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // A - B = A + not B + 1
      5'b00101: begin
        temp_v = {1'b0, A_Data} + {1'b0, ~B_Data} + 5'd1;
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // DEC A
      5'b00110: begin
        temp_v = {1'b0, A_Data} - 5'd1;
        Result = temp_v[3:0];
        C      = temp_v[4];
      end

      // Transfer A
      5'b00111: begin
        Result = A_Data;
      end

      // A AND B
      5'b01000: begin
        Result = A_Data & B_Data;
      end

      // A OR B
      5'b01010: begin
        Result = A_Data | B_Data;
      end

      // A XOR B
      5'b01100: begin
        Result = A_Data ^ B_Data;
      end

      // NOT A
      5'b01110: begin
        Result = ~A_Data;
      end

      // NOT B
      5'b10000: begin
        Result = ~B_Data;
      end

      // SHR B
      5'b10100: begin
        Result = B_Data >> 1;
        C      = B_Data[0];
      end

      // SHL B
      5'b11000: begin
        Result = B_Data << 1;
        C      = B_Data[3];
      end

      default: begin
        Result = 4'b0000;
        C      = 1'b0;
      end
    endcase

    // Cálculo de Overflow (V)
    if (FS == 5'b00010 || FS == 5'b00011) begin
      // Suma A + B
      V = (A_Data[3] & B_Data[3] & ~Result[3]) |
          ((~A_Data[3]) & (~B_Data[3]) & Result[3]);
    end else if (FS == 5'b00001) begin
      // INC A
      V = A_Data[3] & ~Result[3];
    end else if (FS == 5'b00100 || FS == 5'b00101) begin
      // Resta tipo A - B
      V = (A_Data[3] & (~B_Data[3]) & ~Result[3]) |
          ((~A_Data[3]) & B_Data[3] & Result[3]);
    end else if (FS == 5'b00110) begin
      // DEC A: overflow si A = 1000 (-8) y pasa a 0111 (+7)
      if (A_Data == 4'b1000)
        V = 1'b1;
      else
        V = 1'b0;
    end else begin
      V = 1'b0;
    end

    // Banderas N (Negativo) y Z (Cero)
    N = Result[3];
    Z = (Result == 4'b0000) ? 1'b1 : 1'b0;
  end

endmodule
