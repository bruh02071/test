
// pc_reg.v - Program Counter with stall support, active-low reset
module pc_reg #(
    parameter XLEN = 32,
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire            stall_i,     // freeze PC on load-use
    input  wire [XLEN-1:0] pc_next_i,
    output reg  [XLEN-1:0] pc_o
);
    always @(posedge clk) begin
        if (!rst_n)
            pc_o <= RESET_VECTOR;
        else if (!stall_i)
            pc_o <= pc_next_i;
        // else hold (stall)
    end
endmodule
