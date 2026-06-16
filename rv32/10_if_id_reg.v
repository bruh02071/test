
// if_id_reg.v - IF/ID pipeline register
module if_id_reg #(
    parameter XLEN = 32
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire            stall_i,
    input  wire            flush_i,
    input  wire [XLEN-1:0] pc_i,
    input  wire [XLEN-1:0] pc_plus4_i,
    input  wire [31:0]     instr_i,
    output reg  [XLEN-1:0] pc_o,
    output reg  [XLEN-1:0] pc_plus4_o,
    output reg  [31:0]     instr_o
);
    always @(posedge clk) begin
        if (!rst_n || flush_i) begin
            pc_o <= {XLEN{1'b0}}; pc_plus4_o <= {XLEN{1'b0}};
            instr_o <= 32'h0000_0000;   // bubble (NOP)
        end else if (!stall_i) begin
            pc_o <= pc_i; pc_plus4_o <= pc_plus4_i; instr_o <= instr_i;
        end
        // else hold
    end
endmodule
