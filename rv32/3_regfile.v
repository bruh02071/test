// regfile.v - 32x32 register file, dual-read / single-write, x0 = 0
module regfile #(
    parameter XLEN     = 32,
    parameter REG_ADDR = 5
)(
    input  wire             clk,
    input  wire             rst_n,
    // write port
    input  wire             we_i,        // write enable
    input  wire [REG_ADDR-1:0] waddr_i,
    input  wire [XLEN-1:0]  wdata_i,
    // read ports
    input  wire [REG_ADDR-1:0] raddr1_i,
    input  wire [REG_ADDR-1:0] raddr2_i,
    output wire [XLEN-1:0]  rdata1_o,
    output wire [XLEN-1:0]  rdata2_o
);

    integer i;
    reg [XLEN-1:0] regs [0:(1<<REG_ADDR)-1];

    // ---- Sequential write (synchronous, active-low reset) ----
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < (1<<REG_ADDR); i = i + 1)
                regs[i] <= {XLEN{1'b0}};
        end else if (we_i && (waddr_i != {REG_ADDR{1'b0}})) begin
            regs[waddr_i] <= wdata_i;   // x0 never written
        end
    end

    // ---- Combinational read with write-before-read forwarding ----
    assign rdata1_o = (raddr1_i == {REG_ADDR{1'b0}}) ? {XLEN{1'b0}} :
                      (we_i && (waddr_i == raddr1_i)) ? wdata_i :
                      regs[raddr1_i];

    assign rdata2_o = (raddr2_i == {REG_ADDR{1'b0}}) ? {XLEN{1'b0}} :
                      (we_i && (waddr_i == raddr2_i)) ? wdata_i :
                      regs[raddr2_i];

endmodule

