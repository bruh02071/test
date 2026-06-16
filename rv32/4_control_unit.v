
// control_unit.v - Main decoder for RV32I
`include "define.v"

module control_unit (
    input  wire [6:0] opcode_i,
    output reg        reg_write_o,   // write back to regfile
    output reg        mem_read_o,    // load
    output reg        mem_write_o,   // store
    output reg        branch_o,      // conditional branch
    output reg        jump_o,        // JAL/JALR (unconditional)
    output reg        jalr_o,        // JALR uses rs1+imm as target
    output reg        alu_src_o,     // 0: rs2, 1: immediate
    output reg [1:0]  alu_op_o,      // hint to alu_control
    output reg [1:0]  result_src_o,  // 00:ALU 01:MEM 10:PC+4 11:imm(LUI)
    output reg        pc_to_alu_o    // 1: operand A = PC (AUIPC/JAL target)
);
    always @(*) begin
        // safe defaults => NOP, prevents latches
        reg_write_o  = 1'b0; mem_read_o  = 1'b0; mem_write_o = 1'b0;
        branch_o     = 1'b0; jump_o      = 1'b0; jalr_o      = 1'b0;
        alu_src_o    = 1'b0; alu_op_o    = 2'b00;
        result_src_o = 2'b00; pc_to_alu_o = 1'b0;
        case (opcode_i)
            `OP_RTYPE: begin
                reg_write_o = 1'b1; alu_src_o = 1'b0; alu_op_o = 2'b10;
            end
            `OP_ITYPE: begin
                reg_write_o = 1'b1; alu_src_o = 1'b1; alu_op_o = 2'b10;
            end
            `OP_LOAD: begin
                reg_write_o = 1'b1; mem_read_o = 1'b1; alu_src_o = 1'b1;
                alu_op_o = 2'b00; result_src_o = 2'b01;
            end
            `OP_STORE: begin
                mem_write_o = 1'b1; alu_src_o = 1'b1; alu_op_o = 2'b00;
            end
            `OP_BRANCH: begin
                branch_o = 1'b1; alu_src_o = 1'b0; alu_op_o = 2'b01;
            end
            `OP_JAL: begin
                reg_write_o = 1'b1; jump_o = 1'b1; result_src_o = 2'b10;
                pc_to_alu_o = 1'b1; alu_src_o = 1'b1; alu_op_o = 2'b00;
            end
            `OP_JALR: begin
                reg_write_o = 1'b1; jump_o = 1'b1; jalr_o = 1'b1;
                result_src_o = 2'b10; alu_src_o = 1'b1; alu_op_o = 2'b00;
            end
            `OP_LUI: begin
                reg_write_o = 1'b1; alu_src_o = 1'b1; alu_op_o = 2'b11;
                result_src_o = 2'b00;
            end
            `OP_AUIPC: begin
                reg_write_o = 1'b1; alu_src_o = 1'b1; alu_op_o = 2'b00;
                pc_to_alu_o = 1'b1; result_src_o = 2'b00;
            end
            `OP_FENCE, `OP_SYSTEM: begin
                // FENCE / ECALL / EBREAK -> NOP (defaults already set)
            end
            default: begin
                // illegal -> NOP (defaults), no latch
            end
        endcase
    end
endmodule
