
// alu.v - Combinational ALU for RV32I
`include "define.v"

module alu #(
    parameter XLEN = 32
)(
    input  wire [XLEN-1:0] op_a_i,      // operand A
    input  wire [XLEN-1:0] op_b_i,      // operand B
    input  wire [3:0]      alu_ctrl_i,  // operation select
    output reg  [XLEN-1:0] result_o,    // ALU result
    output wire            zero_o       // result == 0 (for branches)
);

    // shift amount: low 5 bits of operand B (RV32I)
    wire [4:0] shamt = op_b_i[4:0];

    always @(*) begin
        case (alu_ctrl_i)
            `ALU_ADD : result_o = op_a_i + op_b_i;
            `ALU_SUB : result_o = op_a_i - op_b_i;
            `ALU_SLL : result_o = op_a_i << shamt;
            `ALU_SLT : result_o = ($signed(op_a_i) < $signed(op_b_i)) ? 32'd1 : 32'd0;
            `ALU_SLTU: result_o = (op_a_i < op_b_i) ? 32'd1 : 32'd0;
            `ALU_XOR : result_o = op_a_i ^ op_b_i;
            `ALU_SRL : result_o = op_a_i >> shamt;
            `ALU_SRA : result_o = $signed(op_a_i) >>> shamt;
            `ALU_OR  : result_o = op_a_i | op_b_i;
            `ALU_AND : result_o = op_a_i & op_b_i;
            `ALU_LUI : result_o = op_b_i;            // pass immediate through
            default  : result_o = {XLEN{1'b0}};      // no latch
        endcase
    end

    assign zero_o = (result_o == {XLEN{1'b0}});

endmodule
