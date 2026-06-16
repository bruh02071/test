// hazard_unit.v - Forwarding + load-use stall + branch/jump flush
module hazard_unit (
    // source registers in ID/EX (consumed in EX)
    input  wire [4:0] ex_rs1_i,
    input  wire [4:0] ex_rs2_i,
    // destination registers downstream
    input  wire [4:0] mem_rd_i,     // EX/MEM dest
    input  wire [4:0] wb_rd_i,      // MEM/WB dest
    input  wire       mem_reg_write_i,
    input  wire       wb_reg_write_i,
    // load-use detection: instr currently in EX
    input  wire       ex_mem_read_i, // EX-stage is a load
    input  wire [4:0] ex_rd_i,       // EX-stage dest
    input  wire [4:0] id_rs1_i,      // sources being decoded in ID
    input  wire [4:0] id_rs2_i,
    // control hazard
    input  wire       branch_taken_i, // resolved taken branch or jump in EX
    // outputs
    output reg  [1:0] forward_a_o,    // 00 reg, 10 EX/MEM, 01 MEM/WB
    output reg  [1:0] forward_b_o,
    output wire       stall_o,        // freeze PC + IF/ID, bubble ID/EX
    output wire       flush_if_id_o,
    output wire       flush_id_ex_o
);
    // ---- Forwarding (EX/MEM has priority over MEM/WB) ----
    always @(*) begin
        // operand A
        if (mem_reg_write_i && (mem_rd_i != 5'd0) && (mem_rd_i == ex_rs1_i))
            forward_a_o = 2'b10;
        else if (wb_reg_write_i && (wb_rd_i != 5'd0) && (wb_rd_i == ex_rs1_i))
            forward_a_o = 2'b01;
        else
            forward_a_o = 2'b00;
        // operand B
        if (mem_reg_write_i && (mem_rd_i != 5'd0) && (mem_rd_i == ex_rs2_i))
            forward_b_o = 2'b10;
        else if (wb_reg_write_i && (wb_rd_i != 5'd0) && (wb_rd_i == ex_rs2_i))
            forward_b_o = 2'b01;
        else
            forward_b_o = 2'b00;
    end

    // ---- Load-use hazard: load in EX feeding an ID source ----
    wire load_use = ex_mem_read_i && (ex_rd_i != 5'd0) &&
                    ((ex_rd_i == id_rs1_i) || (ex_rd_i == id_rs2_i));
    assign stall_o = load_use;

    // ---- Control hazard: flush younger instrs on taken branch/jump ----
    assign flush_if_id_o = branch_taken_i;
    assign flush_id_ex_o = branch_taken_i;

endmodule

