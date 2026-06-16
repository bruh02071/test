// id_ex_reg.v - ID/EX pipeline register
module id_ex_reg #(
    parameter XLEN = 32
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire            flush_i,        // bubble on stall or branch
    // control signals
    input  wire            reg_write_i, mem_read_i, mem_write_i,
    input  wire            branch_i, jump_i, jalr_i, alu_src_i, pc_to_alu_i,
    input  wire [1:0]      alu_op_i, result_src_i,
    // data
    input  wire [XLEN-1:0] pc_i, pc_plus4_i, rs1_data_i, rs2_data_i, imm_i,
    input  wire [4:0]      rs1_i, rs2_i, rd_i,
    input  wire [2:0]      funct3_i,
    input  wire            funct7b5_i,
    input  wire            is_itype_i,
    // outputs (same bundle)
    output reg             reg_write_o, mem_read_o, mem_write_o,
    output reg             branch_o, jump_o, jalr_o, alu_src_o, pc_to_alu_o,
    output reg [1:0]       alu_op_o, result_src_o,
    output reg [XLEN-1:0]  pc_o, pc_plus4_o, rs1_data_o, rs2_data_o, imm_o,
    output reg [4:0]       rs1_o, rs2_o, rd_o,
    output reg [2:0]       funct3_o,
    output reg             funct7b5_o,
    output reg             is_itype_o
);
    always @(posedge clk) begin
        if (!rst_n || flush_i) begin
            // clear control -> NOP; zero data
            reg_write_o <= 1'b0; mem_read_o <= 1'b0; mem_write_o <= 1'b0;
            branch_o <= 1'b0; jump_o <= 1'b0; jalr_o <= 1'b0;
            alu_src_o <= 1'b0; pc_to_alu_o <= 1'b0;
            alu_op_o <= 2'b00; result_src_o <= 2'b00;
            pc_o <= {XLEN{1'b0}}; pc_plus4_o <= {XLEN{1'b0}};
            rs1_data_o <= {XLEN{1'b0}}; rs2_data_o <= {XLEN{1'b0}};
            imm_o <= {XLEN{1'b0}};
            rs1_o <= 5'd0; rs2_o <= 5'd0; rd_o <= 5'd0;
            funct3_o <= 3'b0; funct7b5_o <= 1'b0; is_itype_o <= 1'b0;
        end else begin
            reg_write_o <= reg_write_i; mem_read_o <= mem_read_i;
            mem_write_o <= mem_write_i; branch_o <= branch_i;
            jump_o <= jump_i; jalr_o <= jalr_i; alu_src_o <= alu_src_i;
            pc_to_alu_o <= pc_to_alu_i; alu_op_o <= alu_op_i;
            result_src_o <= result_src_i;
            pc_o <= pc_i; pc_plus4_o <= pc_plus4_i;
            rs1_data_o <= rs1_data_i; rs2_data_o <= rs2_data_i; imm_o <= imm_i;
            rs1_o <= rs1_i; rs2_o <= rs2_i; rd_o <= rd_i;
            funct3_o <= funct3_i; funct7b5_o <= funct7b5_i;
            is_itype_o <= is_itype_i;
        end
    end
endmodule

