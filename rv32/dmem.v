
// dmem.v - Data memory: byte/half/word, 1-cycle sync, with load extension
`include "define.v"

module dmem #(
    parameter XLEN  = 32,
    parameter DEPTH = 1024            // words
)(
    input  wire            clk,
    input  wire            mem_read_i,
    input  wire            mem_write_i,
    input  wire [2:0]      funct3_i,   // size/sign
    input  wire [XLEN-1:0] addr_i,     // byte address (ALU result)
    input  wire [XLEN-1:0] wdata_i,    // store data (forwarded rs2)
    output reg  [XLEN-1:0] rdata_o     // extended load result
);
    reg [XLEN-1:0] mem [0:DEPTH-1];
    wire [$clog2(DEPTH)-1:0] widx = addr_i[$clog2(DEPTH)+1:2];
    wire [1:0] boff = addr_i[1:0];     // byte offset within word
    reg  [XLEN-1:0] rword;

    // ---- Synchronous write with sub-word masking ----
    always @(posedge clk) begin
        if (mem_write_i) begin
            case (funct3_i)
                3'b000: // SB
                    case (boff)
                        2'd0: mem[widx][7:0]   <= wdata_i[7:0];
                        2'd1: mem[widx][15:8]  <= wdata_i[7:0];
                        2'd2: mem[widx][23:16] <= wdata_i[7:0];
                        default: mem[widx][31:24] <= wdata_i[7:0];
                    endcase
                3'b001: // SH
                    case (boff[1])
                        1'b0: mem[widx][15:0]  <= wdata_i[15:0];
                        default: mem[widx][31:16] <= wdata_i[15:0];
                    endcase
                default: // SW
                    mem[widx] <= wdata_i;
            endcase
        end
    end

    // ---- Synchronous read ----
    always @(posedge clk)
        rword <= mem[widx];

    // ---- Combinational load extension on the registered word ----
    // boff is stable across the read cycle for aligned single-cycle access
    reg [1:0] boff_q;
    always @(posedge clk) boff_q <= boff;

    always @(*) begin
        case (funct3_i)
            3'b000: begin // LB
                case (boff_q)
                    2'd0: rdata_o = {{24{rword[7]}},  rword[7:0]};
                    2'd1: rdata_o = {{24{rword[15]}}, rword[15:8]};
                    2'd2: rdata_o = {{24{rword[23]}}, rword[23:16]};
                    default: rdata_o = {{24{rword[31]}}, rword[31:24]};
                endcase
            end
            3'b100: begin // LBU
                case (boff_q)
                    2'd0: rdata_o = {24'b0, rword[7:0]};
                    2'd1: rdata_o = {24'b0, rword[15:8]};
                    2'd2: rdata_o = {24'b0, rword[23:16]};
                    default: rdata_o = {24'b0, rword[31:24]};
                endcase
            end
            3'b001: rdata_o = boff_q[1] ? {{16{rword[31]}}, rword[31:16]}   // LH
                                        : {{16{rword[15]}}, rword[15:0]};
            3'b101: rdata_o = boff_q[1] ? {16'b0, rword[31:16]}             // LHU
                                        : {16'b0, rword[15:0]};
            default: rdata_o = rword;                                       // LW
        endcase
    end
endmodule
