// wb_mux.v - Write-back result selection
`include "define.v"

module wb_mux #(
    parameter XLEN = 32
)(
    input  wire [1:0]      result_src_i,
    input  wire [XLEN-1:0] alu_result_i, mem_data_i, pc_plus4_i, imm_i,
    output reg  [XLEN-1:0] wb_data_o
);
    always @(*) begin
        case (result_src_i)
            2'b00:   wb_data_o = alu_result_i;
            2'b01:   wb_data_o = mem_data_i;
            2'b10:   wb_data_o = pc_plus4_i;
            2'b11:   wb_data_o = imm_i;
            default: wb_data_o = alu_result_i;   // no latch
        endcase
    end
endmodule

