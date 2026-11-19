/*
 * Copyright (c) 202 TECNM-ITTehuacán
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns / 1ps

module ALU (
    input  wire [4:0] FS,
    input  wire [3:0] A_Data,
    input  wire [3:0] B_Data,
    output reg  [3:0] Result,
    output reg        V,
    output reg        C,
    output reg        N,
    output reg        Z
);

    reg [8:0] temp_v;

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
        end
        else if (FS == 5'b00001) begin
            // INC A
            V = A_Data[3] & ~Result[3];
        end
        else if (FS == 5'b00100 || FS == 5'b00101) begin
            // Resta tipo A - B
            V = (A_Data[3] & (~B_Data[3]) & ~Result[3]) |
                ((~A_Data[3]) & B_Data[3] & Result[3]);
        end
        else if (FS == 5'b00110) begin
            // DEC A: overflow si A = 1000 (-8) y pasa a 0111 (+7)
            if (A_Data == 4'b1000)
                V = 1'b1;
            else
                V = 1'b0;
        end
        else begin
            V = 1'b0;
        end

        // Banderas N (Negativo) y Z (Cero)
        N = Result[3];
        Z = (Result == 4'b0000) ? 1'b1 : 1'b0;
    end

endmodule
