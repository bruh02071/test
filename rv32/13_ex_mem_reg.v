
// ex_mem_reg.v - EX/MEM pipeline register
module ex_mem_reg #(
    parameter XLEN = 32
)(
    input  wire            clk, rst_n,
    input  wire            reg_write_i, mem_read_i, mem_write_i,
    input  wire [1:0]      result_src_i,
    input  wire [2:0]      funct3_i,
    input  wire [XLEN-1:0] alu_result_i, rs2_data_i, pc_plus4_i,
    input  wire [4:0]      rd_i,
    output reg             reg_write_o, mem_read_o, mem_write_o,
    output reg [1:0]       result_src_o,
    output reg [2:0]       funct3_o,
    output reg [XLEN-1:0]  alu_result_o, rs2_data_o, pc_plus4_o,
    output reg [4:0]       rd_o
);
    always @(posedge clk) begin
        if (!rst_n) begin
            reg_write_o <= 1'b0; mem_read_o <= 1'b0; mem_write_o <= 1'b0;
            result_src_o <= 2'b00; funct3_o <= 3'b0;
            alu_result_o <= {XLEN{1'b0}}; rs2_data_o <= {XLEN{1'b0}};
            pc_plus4_o <= {XLEN{1'b0}}; rd_o <= 5'd0;
        end else begin
            reg_write_o <= reg_write_i; mem_read_o <= mem_read_i;
            mem_write_o <= mem_write_i; result_src_o <= result_src_i;
            funct3_o <= funct3_i; alu_result_o <= alu_result_i;
            rs2_data_o <= rs2_data_i; pc_plus4_o <= pc_plus4_i; rd_o <= rd_i;
        end
    end
endmodule
