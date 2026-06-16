// ex_stage.v - Execute: forwarding, ALU operands, branch resolve, target
`include "define.v"

module ex_stage #(
    parameter XLEN = 32
)(
    // from ID/EX
    input  wire [XLEN-1:0] pc_i, rs1_data_i, rs2_data_i, imm_i,
    input  wire [1:0]      alu_op_i, forward_a_i, forward_b_i,
    input  wire            alu_src_i, pc_to_alu_i, branch_i, jump_i, jalr_i,
    input  wire [2:0]      funct3_i,
    input  wire            funct7b5_i, is_itype_i,
    // forwarded sources
    input  wire [XLEN-1:0] ex_mem_fwd_i,   // EX/MEM ALU result
    input  wire [XLEN-1:0] wb_fwd_i,       // MEM/WB writeback value
    // outputs
    output wire [XLEN-1:0] alu_result_o,
    output wire [XLEN-1:0] rs2_fwd_o,      // store data (post-forward)
    output wire [XLEN-1:0] branch_target_o,
    output wire            branch_taken_o  // taken branch OR jump
);
    // ---- Forwarding muxes ----
    reg [XLEN-1:0] fwd_a, fwd_b;
    always @(*) begin
        case (forward_a_i)
            2'b10:   fwd_a = ex_mem_fwd_i;
            2'b01:   fwd_a = wb_fwd_i;
            default: fwd_a = rs1_data_i;
        endcase
        case (forward_b_i)
            2'b10:   fwd_b = ex_mem_fwd_i;
            2'b01:   fwd_b = wb_fwd_i;
            default: fwd_b = rs2_data_i;
        endcase
    end
    assign rs2_fwd_o = fwd_b;   // store data uses forwarded rs2

    // ---- ALU operand selection ----
    wire [XLEN-1:0] op_a = pc_to_alu_i ? pc_i  : fwd_a;
    wire [XLEN-1:0] op_b = alu_src_i   ? imm_i : fwd_b;

    // ---- ALU control + ALU ----
    wire [3:0] alu_ctrl;
    alu_control u_alu_ctrl (
        .alu_op_i(alu_op_i), .funct3_i(funct3_i),
        .funct7b5_i(funct7b5_i), .is_itype_i(is_itype_i),
        .alu_ctrl_o(alu_ctrl)
    );
    alu #(.XLEN(XLEN)) u_alu (
        .op_a_i(op_a), .op_b_i(op_b), .alu_ctrl_i(alu_ctrl),
        .result_o(alu_result_o), .zero_o(/*unused: comparator below*/)
    );

    // ---- Branch comparator (uses forwarded operands directly) ----
    reg cond;
    always @(*) begin
        case (funct3_i)
            `F3_BEQ : cond = (fwd_a == fwd_b);
            `F3_BNE : cond = (fwd_a != fwd_b);
            `F3_BLT : cond = ($signed(fwd_a) <  $signed(fwd_b));
            `F3_BGE : cond = ($signed(fwd_a) >= $signed(fwd_b));
            `F3_BLTU: cond = (fwd_a <  fwd_b);
            `F3_BGEU: cond = (fwd_a >= fwd_b);
            default : cond = 1'b0;   // no latch
        endcase
    end
    assign branch_taken_o = jump_i | (branch_i & cond);

    // ---- Target: JALR uses rs1+imm, others PC+imm ----
    assign branch_target_o = (jalr_i ? fwd_a : pc_i) + imm_i;

endmodule

