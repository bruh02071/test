// alu_control.v - Derives ALU operation from alu_op + funct fields
`include "define.v"

module alu_control (
    input  wire [1:0] alu_op_i,     // hint from control_unit
    input  wire [2:0] funct3_i,     // instr[14:12]
    input  wire       funct7b5_i,   // instr[30]
    input  wire       is_itype_i,   // 1 if I-type ALU op
    output reg  [3:0] alu_ctrl_o
);
    always @(*) begin
        case (alu_op_i)
            2'b00: alu_ctrl_o = `ALU_ADD;   // load/store/jal/jalr/auipc
            2'b01: alu_ctrl_o = `ALU_SUB;   // branch: subtract to compare
            2'b11: alu_ctrl_o = `ALU_LUI;   // LUI pass-through
            2'b10: begin                    // R-type / I-type ALU
                case (funct3_i)
                    `F3_ADD_SUB: alu_ctrl_o = (!is_itype_i && funct7b5_i) ?
                                              `ALU_SUB : `ALU_ADD; // ADDI never SUB
                    `F3_SLL : alu_ctrl_o = `ALU_SLL;
                    `F3_SLT : alu_ctrl_o = `ALU_SLT;
                    `F3_SLTU: alu_ctrl_o = `ALU_SLTU;
                    `F3_XOR : alu_ctrl_o = `ALU_XOR;
                    `F3_SR  : alu_ctrl_o = (funct7b5_i) ? `ALU_SRA : `ALU_SRL; // SRAI/SRA via bit30
                    `F3_OR  : alu_ctrl_o = `ALU_OR;
                    `F3_AND : alu_ctrl_o = `ALU_AND;
                    default : alu_ctrl_o = `ALU_ADD; // no latch
                endcase
            end
            default: alu_ctrl_o = `ALU_ADD;          // no latch
        endcase
    end
endmodule

