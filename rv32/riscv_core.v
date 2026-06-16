
// riscv_core.v - 5-stage RV32I top-level datapath
`include "define.v"

module riscv_core #(
    parameter XLEN = 32,
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  wire clk,
    input  wire rst_n
);
    // ---------------- IF stage ----------------
    wire [XLEN-1:0] pc_if, pc_next, instr_if;
    wire [XLEN-1:0] pc_plus4_if = pc_if + 32'd4;

    // hazard / control-flow signals (declared early for next-PC mux)
    wire        stall, flush_if_id, flush_id_ex;
    wire        branch_taken_ex;
    wire [XLEN-1:0] branch_target_ex;

    assign pc_next = branch_taken_ex ? branch_target_ex : pc_plus4_if;

    pc_reg #(.XLEN(XLEN), .RESET_VECTOR(RESET_VECTOR)) u_pc (
        .clk(clk), .rst_n(rst_n), .stall_i(stall),
        .pc_next_i(pc_next), .pc_o(pc_if)
    );
    imem #(.XLEN(XLEN)) u_imem (
        .clk(clk), .addr_i(pc_if), .instr_o(instr_if)
    );

    // ---------------- IF/ID ----------------
    wire [XLEN-1:0] pc_id, pc_plus4_id;
    wire [31:0]     instr_id;
    if_id_reg #(.XLEN(XLEN)) u_if_id (
        .clk(clk), .rst_n(rst_n),
        .stall_i(stall), .flush_i(flush_if_id),
        .pc_i(pc_if), .pc_plus4_i(pc_plus4_if), .instr_i(instr_if),
        .pc_o(pc_id), .pc_plus4_o(pc_plus4_id), .instr_o(instr_id)
    );

    // ---------------- ID stage ----------------
    wire [6:0] opcode_id = instr_id[6:0];
    wire [4:0] rs1_id = instr_id[19:15];
    wire [4:0] rs2_id = instr_id[24:20];
    wire [4:0] rd_id  = instr_id[11:7];
    wire [2:0] funct3_id = instr_id[14:12];
    wire       funct7b5_id = instr_id[30];
    wire       is_itype_id = (opcode_id == `OP_ITYPE);

    wire reg_write_id, mem_read_id, mem_write_id, branch_id, jump_id, jalr_id;
    wire alu_src_id, pc_to_alu_id;
    wire [1:0] alu_op_id, result_src_id;
    control_unit u_ctrl (
        .opcode_i(opcode_id),
        .reg_write_o(reg_write_id), .mem_read_o(mem_read_id),
        .mem_write_o(mem_write_id), .branch_o(branch_id),
        .jump_o(jump_id), .jalr_o(jalr_id), .alu_src_o(alu_src_id),
        .alu_op_o(alu_op_id), .result_src_o(result_src_id),
        .pc_to_alu_o(pc_to_alu_id)
    );

    wire [XLEN-1:0] rs1_data_id, rs2_data_id, imm_id;
    // write-back signals (declared early for regfile write port)
    wire        reg_write_wb;
    wire [4:0]  rd_wb;
    wire [XLEN-1:0] wb_data;

    regfile #(.XLEN(XLEN)) u_rf (
        .clk(clk), .rst_n(rst_n),
        .we_i(reg_write_wb), .waddr_i(rd_wb), .wdata_i(wb_data),
        .raddr1_i(rs1_id), .raddr2_i(rs2_id),
        .rdata1_o(rs1_data_id), .rdata2_o(rs2_data_id)
    );
    imm_gen #(.XLEN(XLEN)) u_imm (
        .instr_i(instr_id), .imm_o(imm_id)
    );

    // ---------------- ID/EX ----------------
    wire reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex, jalr_ex;
    wire alu_src_ex, pc_to_alu_ex;
    wire [1:0] alu_op_ex, result_src_ex;
    wire [XLEN-1:0] pc_ex, pc_plus4_ex, rs1_data_ex, rs2_data_ex, imm_ex;
    wire [4:0] rs1_ex, rs2_ex, rd_ex;
    wire [2:0] funct3_ex;
    wire funct7b5_ex, is_itype_ex;

    id_ex_reg #(.XLEN(XLEN)) u_id_ex (
        .clk(clk), .rst_n(rst_n),
        .flush_i(stall | flush_id_ex),   // bubble on load-use or branch flush
        .reg_write_i(reg_write_id), .mem_read_i(mem_read_id),
        .mem_write_i(mem_write_id), .branch_i(branch_id), .jump_i(jump_id),
        .jalr_i(jalr_id), .alu_src_i(alu_src_id), .pc_to_alu_i(pc_to_alu_id),
        .alu_op_i(alu_op_id), .result_src_i(result_src_id),
        .pc_i(pc_id), .pc_plus4_i(pc_plus4_id),
        .rs1_data_i(rs1_data_id), .rs2_data_i(rs2_data_id), .imm_i(imm_id),
        .rs1_i(rs1_id), .rs2_i(rs2_id), .rd_i(rd_id),
        .funct3_i(funct3_id), .funct7b5_i(funct7b5_id), .is_itype_i(is_itype_id),
        .reg_write_o(reg_write_ex), .mem_read_o(mem_read_ex),
        .mem_write_o(mem_write_ex), .branch_o(branch_ex), .jump_o(jump_ex),
        .jalr_o(jalr_ex), .alu_src_o(alu_src_ex), .pc_to_alu_o(pc_to_alu_ex),
        .alu_op_o(alu_op_ex), .result_src_o(result_src_ex),
        .pc_o(pc_ex), .pc_plus4_o(pc_plus4_ex),
        .rs1_data_o(rs1_data_ex), .rs2_data_o(rs2_data_ex), .imm_o(imm_ex),
        .rs1_o(rs1_ex), .rs2_o(rs2_ex), .rd_o(rd_ex),
        .funct3_o(funct3_ex), .funct7b5_o(funct7b5_ex), .is_itype_o(is_itype_ex)
    );

    // ---------------- EX stage ----------------
    wire [XLEN-1:0] alu_result_ex, rs2_fwd_ex;
    wire [1:0] forward_a, forward_b;
    // downstream signals for forwarding (declared early)
    wire reg_write_mem;
    wire [4:0] rd_mem;
    wire [XLEN-1:0] alu_result_mem;

    ex_stage #(.XLEN(XLEN)) u_ex (
        .pc_i(pc_ex), .rs1_data_i(rs1_data_ex), .rs2_data_i(rs2_data_ex),
        .imm_i(imm_ex), .alu_op_i(alu_op_ex),
        .forward_a_i(forward_a), .forward_b_i(forward_b),
        .alu_src_i(alu_src_ex), .pc_to_alu_i(pc_to_alu_ex),
        .branch_i(branch_ex), .jump_i(jump_ex), .jalr_i(jalr_ex),
        .funct3_i(funct3_ex), .funct7b5_i(funct7b5_ex), .is_itype_i(is_itype_ex),
        .ex_mem_fwd_i(alu_result_mem), .wb_fwd_i(wb_data),
        .alu_result_o(alu_result_ex), .rs2_fwd_o(rs2_fwd_ex),
        .branch_target_o(branch_target_ex), .branch_taken_o(branch_taken_ex)
    );

    // ---------------- EX/MEM ----------------
    wire mem_read_mem, mem_write_mem;
    wire [1:0] result_src_mem;
    wire [2:0] funct3_mem;
    wire [XLEN-1:0] rs2_data_mem, pc_plus4_mem;

    ex_mem_reg #(.XLEN(XLEN)) u_ex_mem (
        .clk(clk), .rst_n(rst_n),
        .reg_write_i(reg_write_ex), .mem_read_i(mem_read_ex),
        .mem_write_i(mem_write_ex), .result_src_i(result_src_ex),
        .funct3_i(funct3_ex), .alu_result_i(alu_result_ex),
        .rs2_data_i(rs2_fwd_ex), .pc_plus4_i(pc_plus4_ex), .rd_i(rd_ex),
        .reg_write_o(reg_write_mem), .mem_read_o(mem_read_mem),
        .mem_write_o(mem_write_mem), .result_src_o(result_src_mem),
        .funct3_o(funct3_mem), .alu_result_o(alu_result_mem),
        .rs2_data_o(rs2_data_mem), .pc_plus4_o(pc_plus4_mem), .rd_o(rd_mem)
    );

    // ---------------- MEM stage ----------------
    wire [XLEN-1:0] mem_data_mem;
    dmem #(.XLEN(XLEN)) u_dmem (
        .clk(clk), .mem_read_i(mem_read_mem), .mem_write_i(mem_write_mem),
        .funct3_i(funct3_mem), .addr_i(alu_result_mem),
        .wdata_i(rs2_data_mem), .rdata_o(mem_data_mem)
    );

    // ---------------- MEM/WB ----------------
    wire [1:0] result_src_wb;
    wire [XLEN-1:0] mem_data_wb, alu_result_wb, pc_plus4_wb, imm_wb;
    mem_wb_reg #(.XLEN(XLEN)) u_mem_wb (
        .clk(clk), .rst_n(rst_n),
        .reg_write_i(reg_write_mem), .result_src_i(result_src_mem),
        .mem_data_i(mem_data_mem), .alu_result_i(alu_result_mem),
        .pc_plus4_i(pc_plus4_mem), .imm_i(imm_ex), .rd_i(rd_mem),
        .reg_write_o(reg_write_wb), .result_src_o(result_src_wb),
        .mem_data_o(mem_data_wb), .alu_result_o(alu_result_wb),
        .pc_plus4_o(pc_plus4_wb), .imm_o(imm_wb), .rd_o(rd_wb)
    );

    // ---------------- WB stage ----------------
    wb_mux #(.XLEN(XLEN)) u_wb (
        .result_src_i(result_src_wb),
        .alu_result_i(alu_result_wb), .mem_data_i(mem_data_wb),
        .pc_plus4_i(pc_plus4_wb), .imm_i(imm_wb),
        .wb_data_o(wb_data)
    );

    // ---------------- Hazard unit ----------------
    hazard_unit u_hazard (
        .ex_rs1_i(rs1_ex), .ex_rs2_i(rs2_ex),
        .mem_rd_i(rd_mem), .wb_rd_i(rd_wb),
        .mem_reg_write_i(reg_write_mem), .wb_reg_write_i(reg_write_wb),
        .ex_mem_read_i(mem_read_ex), .ex_rd_i(rd_ex),
        .id_rs1_i(rs1_id), .id_rs2_i(rs2_id),
        .branch_taken_i(branch_taken_ex),
        .forward_a_o(forward_a), .forward_b_o(forward_b),
        .stall_o(stall),
        .flush_if_id_o(flush_if_id), .flush_id_ex_o(flush_id_ex)
    );
endmodule
