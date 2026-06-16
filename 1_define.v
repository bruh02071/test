
// define.v - RV32I opcodes, funct fields, and ALU operation constants
`ifndef DEFINE_V
`define DEFINE_V

// ---------- Opcodes (instr[6:0]) ----------
`define OP_RTYPE    7'b0110011  // ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
`define OP_ITYPE    7'b0010011  // ADDI/SLTI/.../SRAI
`define OP_LOAD     7'b0000011  // LB/LH/LW/LBU/LHU
`define OP_STORE    7'b0100011  // SB/SH/SW
`define OP_BRANCH   7'b1100011  // BEQ/BNE/BLT/BGE/BLTU/BGEU
`define OP_JAL      7'b1101111  // JAL
`define OP_JALR     7'b1100111  // JALR
`define OP_LUI      7'b0110111  // LUI
`define OP_AUIPC    7'b0010111  // AUIPC
`define OP_FENCE    7'b0001111  // FENCE (treated as NOP)
`define OP_SYSTEM   7'b1110011  // ECALL/EBREAK (treated as NOP/trap)

// ---------- funct3 ----------
`define F3_ADD_SUB  3'b000
`define F3_SLL      3'b001
`define F3_SLT      3'b010
`define F3_SLTU     3'b011
`define F3_XOR      3'b100
`define F3_SR       3'b101  // SRL/SRA
`define F3_OR       3'b110
`define F3_AND      3'b111

// branch funct3
`define F3_BEQ      3'b000
`define F3_BNE      3'b001
`define F3_BLT      3'b100
`define F3_BGE      3'b101
`define F3_BLTU     3'b110
`define F3_BGEU     3'b111

// ---------- ALU operation codes (internal, 4-bit) ----------
`define ALU_ADD     4'b0000
`define ALU_SUB     4'b0001
`define ALU_SLL     4'b0010
`define ALU_SLT     4'b0011
`define ALU_SLTU    4'b0100
`define ALU_XOR     4'b0101
`define ALU_SRL     4'b0110
`define ALU_SRA     4'b0111
`define ALU_OR      4'b1000
`define ALU_AND     4'b1001
`define ALU_LUI     4'b1010  // pass operand B (immediate) through

`endif
