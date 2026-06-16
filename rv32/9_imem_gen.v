// imm_gen.v - RV32I immediate generator (I/S/B/U/J)
`include "define.v"

module imm_gen #(
    parameter XLEN = 32
)(
    input  wire [31:0]      instr_i,
    output reg  [XLEN-1:0]  imm_o
);
    wire [6:0] opcode = instr_i[6:0];
    always @(*) begin
        case (opcode)
            `OP_ITYPE, `OP_LOAD, `OP_JALR:   // I-type
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            `OP_STORE:                        // S-type
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            `OP_BRANCH:                       // B-type (<<1 implicit)
                imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                         instr_i[30:25], instr_i[11:8], 1'b0};
            `OP_LUI, `OP_AUIPC:               // U-type
                imm_o = {instr_i[31:12], 12'b0};
            `OP_JAL:                          // J-type (<<1 implicit)
                imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                         instr_i[20], instr_i[30:21], 1'b0};
            default:
                imm_o = {XLEN{1'b0}};         // no latch
        endcase
    end
endmodule

