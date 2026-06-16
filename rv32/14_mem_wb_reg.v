// mem_wb_reg.v - MEM/WB pipeline register
module mem_wb_reg #(
    parameter XLEN = 32
)(
    input  wire            clk, rst_n,
    input  wire            reg_write_i,
    input  wire [1:0]      result_src_i,
    input  wire [XLEN-1:0] mem_data_i, alu_result_i, pc_plus4_i, imm_i,
    input  wire [4:0]      rd_i,
    output reg             reg_write_o,
    output reg [1:0]       result_src_o,
    output reg [XLEN-1:0]  mem_data_o, alu_result_o, pc_plus4_o, imm_o,
    output reg [4:0]       rd_o
);
    always @(posedge clk) begin
        if (!rst_n) begin
            reg_write_o <= 1'b0; result_src_o <= 2'b00;
            mem_data_o <= {XLEN{1'b0}}; alu_result_o <= {XLEN{1'b0}};
            pc_plus4_o <= {XLEN{1'b0}}; imm_o <= {XLEN{1'b0}}; rd_o <= 5'd0;
        end else begin
            reg_write_o <= reg_write_i; result_src_o <= result_src_i;
            mem_data_o <= mem_data_i; alu_result_o <= alu_result_i;
            pc_plus4_o <= pc_plus4_i; imm_o <= imm_i; rd_o <= rd_i;
        end
    end
endmodule

