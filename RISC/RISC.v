// ============================================================
// 16-BIT RISC PROCESSOR
// ============================================================
// Datapath     : 16 bits
// Registers    : 8 registers, each 16 bits
// Program Counter : 16 bits
// Instruction  : 16 bits
//
// INSTRUCTION FORMAT
//
// R-TYPE:
// [15:12] OPCODE
// [11:9]  RD
// [8:6]   RS1
// [5:3]   RS2
// [2:0]   UNUSED
//
// I-TYPE:
// [15:12] OPCODE
// [11:9]  RD / RS2
// [8:6]   RS1
// [5:0]   IMMEDIATE
//
// ============================================================

`timescale 1ns/1ps

module RISC16 (
    input clk,
    input reset
);

    // ========================================================
    // OPCODES
    // ========================================================

    parameter ADD  = 4'b0000;
    parameter SUB  = 4'b0001;
    parameter ANDD = 4'b0010;
    parameter ORR  = 4'b0011;
    parameter ADDI = 4'b0100;
    parameter LD   = 4'b0101;
    parameter ST   = 4'b0110;
    parameter BEQ  = 4'b0111;
    parameter JMP  = 4'b1000;
    parameter HALT = 4'b1111;

    // ========================================================
    // PROGRAM COUNTER
    // ========================================================

    reg [15:0] PC;

    // ========================================================
    // INSTRUCTION REGISTER
    // ========================================================

    reg [15:0] instruction;

    // ========================================================
    // REGISTER FILE
    // 8 REGISTERS x 16 BITS
    // ========================================================

    reg [15:0] registers [0:7];

    // ========================================================
    // INSTRUCTION MEMORY
    // 256 LOCATIONS x 16 BITS
    // ========================================================

    reg [15:0] instruction_memory [0:255];

    // ========================================================
    // DATA MEMORY
    // 256 LOCATIONS x 16 BITS
    // ========================================================

    reg [15:0] data_memory [0:255];

    // ========================================================
    // TEMPORARY VARIABLES
    // ========================================================

    reg [15:0] alu_result;
    reg [15:0] memory_address;
    reg halted;

    integer i;

    // ========================================================
    // INSTRUCTION FETCH
    // ========================================================

    always @(posedge clk) begin

        if (reset) begin

            // Reset PC
            PC <= 16'd0;

            // Processor running
            halted <= 1'b0;

            // Clear registers
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'd0;

            // Clear data memory
            for (i = 0; i < 256; i = i + 1)
                data_memory[i] <= 16'd0;

        end

        else if (!halted) begin

            // =================================================
            // FETCH
            // =================================================

            instruction = instruction_memory[PC];

            // =================================================
            // DECODE AND EXECUTE
            // =================================================

            case (instruction[15:12])

                // =================================================
                // ADD
                // Rd = Rs1 + Rs2
                // =================================================

                ADD: begin

                    alu_result =
                        registers[instruction[8:6]] +
                        registers[instruction[5:3]];

                    registers[instruction[11:9]] <= alu_result;

                    PC <= PC + 1;

                end


                // =================================================
                // SUB
                // Rd = Rs1 - Rs2
                // =================================================

                SUB: begin

                    alu_result =
                        registers[instruction[8:6]] -
                        registers[instruction[5:3]];

                    registers[instruction[11:9]] <= alu_result;

                    PC <= PC + 1;

                end


                // =================================================
                // AND
                // Rd = Rs1 AND Rs2
                // =================================================

                ANDD: begin

                    alu_result =
                        registers[instruction[8:6]] &
                        registers[instruction[5:3]];

                    registers[instruction[11:9]] <= alu_result;

                    PC <= PC + 1;

                end


                // =================================================
                // OR
                // Rd = Rs1 OR Rs2
                // =================================================

                ORR: begin

                    alu_result =
                        registers[instruction[8:6]] |
                        registers[instruction[5:3]];

                    registers[instruction[11:9]] <= alu_result;

                    PC <= PC + 1;

                end


                // =================================================
                // ADDI
                // Rd = Rs1 + Immediate
                // =================================================

                ADDI: begin

                    alu_result =
                        registers[instruction[8:6]] +
                        {{10{instruction[5]}}, instruction[5:0]};

                    registers[instruction[11:9]] <= alu_result;

                    PC <= PC + 1;

                end


                // =================================================
                // LOAD
                // Rd = Memory[Rs1 + Immediate]
                // =================================================

                LD: begin

                    memory_address =
                        registers[instruction[8:6]] +
                        {{10{instruction[5]}}, instruction[5:0]};

                    registers[instruction[11:9]]
                        <= data_memory[memory_address];

                    PC <= PC + 1;

                end


                // =================================================
                // STORE
                // Memory[Rs1 + Immediate] = Rs2
                //
                // [11:9] = DATA REGISTER
                // [8:6]  = BASE REGISTER
                // [5:0]  = OFFSET
                // =================================================

                ST: begin

                    memory_address =
                        registers[instruction[8:6]] +
                        {{10{instruction[5]}}, instruction[5:0]};

                    data_memory[memory_address]
                        <= registers[instruction[11:9]];

                    PC <= PC + 1;

                end


                // =================================================
                // BEQ
                // Branch if Rs1 == Rs2
                // =================================================

                BEQ: begin

                    if (registers[instruction[11:9]] ==
                        registers[instruction[8:6]]) begin

                        PC <= PC + 1 +
                              {{10{instruction[5]}}, instruction[5:0]};

                    end

                    else begin

                        PC <= PC + 1;

                    end

                end


                // =================================================
                // JMP
                // PC = 12-BIT ADDRESS
                // =================================================

                JMP: begin

                    PC <= {4'b0000, instruction[11:0]};

                end


                // =================================================
                // HALT
                // =================================================

                HALT: begin

                    halted <= 1'b1;

                end


                // =================================================
                // INVALID INSTRUCTION
                // =================================================

                default: begin

                    PC <= PC + 1;

                end

            endcase

        end

    end

endmodule