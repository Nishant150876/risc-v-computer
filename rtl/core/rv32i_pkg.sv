`timescale 1ns/1ps

// Shared Phase 1 contracts. This package contains no architectural state.
package rv32i_pkg;
    typedef enum logic [6:0] {
        OPCODE_LUI      = 7'b0110111,
        OPCODE_AUIPC    = 7'b0010111,
        OPCODE_JAL      = 7'b1101111,
        OPCODE_JALR     = 7'b1100111,
        OPCODE_BRANCH   = 7'b1100011,
        OPCODE_LOAD     = 7'b0000011,
        OPCODE_STORE    = 7'b0100011,
        OPCODE_OP_IMM   = 7'b0010011,
        OPCODE_OP       = 7'b0110011,
        OPCODE_MISC_MEM = 7'b0001111,
        OPCODE_SYSTEM   = 7'b1110011
    } opcode_t;

    typedef enum logic [6:0] {
        FUNCT7_BASE = 7'b0000000, FUNCT7_ALT = 7'b0100000
    } funct7_t;
    typedef enum logic [31:0] {
        INSTR_ECALL = 32'h0000_0073, INSTR_EBREAK = 32'h0010_0073
    } system_instr_t;

    typedef enum logic [3:0] {
        ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
        ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU
    } alu_op_t;

    typedef enum logic [1:0] { OPA_RS1, OPA_PC, OPA_ZERO } op_a_sel_t;
    typedef enum logic { OPB_RS2, OPB_IMM } op_b_sel_t;
    typedef enum logic [2:0] { IMM_NONE, IMM_I, IMM_S, IMM_B, IMM_U, IMM_J } imm_sel_t;
    typedef enum logic [2:0] {
        BR_NONE, BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU
    } branch_t;
    typedef enum logic [1:0] { JUMP_NONE, JUMP_JAL, JUMP_JALR } jump_t;
    typedef enum logic [1:0] { WB_ALU, WB_MEM, WB_PC4 } wb_sel_t;
    typedef enum logic [1:0] { MEM_BYTE, MEM_HALF, MEM_WORD } mem_size_t;
    typedef enum logic [1:0] { HALT_NONE, HALT_ECALL, HALT_EBREAK } halt_t;

    typedef struct packed {
        alu_op_t   alu_op;
        op_a_sel_t op_a_sel;
        op_b_sel_t op_b_sel;
        imm_sel_t  imm_sel;
        branch_t   branch;
        jump_t     jump;
        wb_sel_t   wb_sel;
        logic      reg_write;
        logic      uses_rs1;
        logic      uses_rs2;
        mem_size_t mem_size;
        logic      mem_read;
        logic      mem_write;
        logic      mem_unsigned;
        halt_t     halt;
        logic      illegal;
    } control_t;

    // Zero encodings deliberately select ADD/rs1/rs2 and no side effects.
    // A future valid/retirement signal is separate from this decode record.
    function automatic control_t nop_control();
        return '0;
    endfunction

    function automatic control_t illegal_control();
        control_t disabled;
        disabled = '0;
        disabled.illegal = 1'b1;
        return disabled;
    endfunction
endpackage
