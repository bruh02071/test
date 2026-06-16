
// imem.v - Instruction memory, 1-cycle synchronous read (Harvard)
module imem #(
    parameter XLEN  = 32,
    parameter DEPTH = 1024            // words
)(
    input  wire            clk,
    input  wire [XLEN-1:0] addr_i,    // byte address (PC)
    output reg  [XLEN-1:0] instr_o
);
    reg [XLEN-1:0] mem [0:DEPTH-1];
    // word index drops the 2 byte-offset bits
    wire [$clog2(DEPTH)-1:0] widx = addr_i[$clog2(DEPTH)+1:2];

    always @(posedge clk)
        instr_o <= mem[widx];
endmodule
