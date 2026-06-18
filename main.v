`timescale 1ns/1ps
module main(clk, rst, rs1, rs2, rd, instrn); 

	input clk, rst; 
	input [4:0] rs1, rs2, rd;
	input [3:0] instrn;

	parameter bit_width=32;
	reg [bit_width-1:0] register_bank [0:31];
	reg [bit_width-1:0] RD_OP_rs1, RD_OP_rs2, forwarded_A, forwarded_B;
	reg [4:0] RD_OP_rd, RD_OP_rs1_addr, RD_OP_rs2_addr;
	reg [3:0] RD_OP_instrn;
	reg [4:0] OP_WR_flag_register, Next_flag_register; // [Sign, Zero, Carry, Overflow_ADD, Overflow_SUB] - Flag Register
	reg [bit_width-1:0] OP_WR_ALUout, Next_ALUout;
	reg [4:0] OP_WR_rd;
	parameter ADD=4'b0000, SUB=4'b0001, AND=4'b0010, OR=4'b0011, XOR=4'b0100, NOR=4'b0101, SLL=4'b0110, SRL=4'b0111, SRA=4'b1000, SLT=4'b1001;



	always @(posedge clk) //Stage-1
		begin
		if (rst) begin
			RD_OP_rd <= #2 5'd0;
			RD_OP_rs1_addr <= #2 5'd0;
			RD_OP_rs2_addr <= #2 5'd0;
			RD_OP_rs1 <= #2 {bit_width{1'b0}};
			RD_OP_rs2 <= #2 {bit_width{1'b0}};
			RD_OP_instrn <= #2 4'b0000;
		end else begin
			RD_OP_rs1 <= #2 (rs1 == OP_WR_rd && OP_WR_rd != 5'd0) ? OP_WR_ALUout : register_bank[rs1];
			RD_OP_rs2 <= #2 (rs2 == OP_WR_rd && OP_WR_rd != 5'd0) ? OP_WR_ALUout : register_bank[rs2];
			RD_OP_rd <= #2 rd;
			RD_OP_rs1_addr <= #2 rs1;
			RD_OP_rs2_addr <= #2 rs2;	
			RD_OP_instrn <= #2 instrn;
		end
	end
	
	always @(*) //Stage-2 Combinational 
		begin 
		if(OP_WR_rd != 5'd0) begin 
			forwarded_A = (RD_OP_rs1_addr == OP_WR_rd) ? OP_WR_ALUout : RD_OP_rs1;
			forwarded_B = (RD_OP_rs2_addr == OP_WR_rd) ? OP_WR_ALUout : RD_OP_rs2; end
		else begin 
			forwarded_A = RD_OP_rs1;
			forwarded_B = RD_OP_rs2; end
		Next_flag_register[2] = 1'b0;
		case(RD_OP_instrn)
			ADD: {Next_flag_register[2],Next_ALUout} = #2 forwarded_A + forwarded_B;
			SUB: Next_ALUout = #2 forwarded_A - forwarded_B;
			AND: Next_ALUout = #2 forwarded_A & forwarded_B;
			OR: Next_ALUout = #2 forwarded_A | forwarded_B;
			XOR: Next_ALUout = #2 forwarded_A ^ forwarded_B;
			NOR: Next_ALUout = #2 ~(forwarded_A | forwarded_B);
			SLL: Next_ALUout = #2 forwarded_A << forwarded_B[($clog2(bit_width)-1):0];
			SRL: Next_ALUout = #2 forwarded_A >> forwarded_B[($clog2(bit_width)-1):0];
			SRA: Next_ALUout = #2 $signed(forwarded_A) >>> forwarded_B[($clog2(bit_width)-1):0];
			SLT: Next_ALUout = #2 forwarded_A < forwarded_B;
		    default: Next_ALUout = #2 {bit_width{1'bx}};
		endcase 
		Next_flag_register[3] = #2 (Next_ALUout == 0);
		Next_flag_register[4] = #2 Next_ALUout[bit_width-1];
		Next_flag_register[1] = #2 (RD_OP_instrn == ADD) ?
			(~(forwarded_A[bit_width-1] ^ forwarded_B[bit_width-1]) & (forwarded_A[bit_width-1] ^ Next_ALUout[bit_width-1])) : 1'b0;
		Next_flag_register[0] = #2 (RD_OP_instrn == SUB) ?
			((forwarded_A[bit_width-1] ^ forwarded_B[bit_width-1]) & (forwarded_A[bit_width-1] ^ Next_ALUout[bit_width-1])) : 1'b0;
		end 

	always @(posedge clk) //Stage-2 Sequential 
		begin
		if (rst) begin
			OP_WR_rd <= #2 5'd0;
			OP_WR_ALUout <= #2 {bit_width{1'b0}};
			OP_WR_flag_register <= #2 5'd0;
		end else begin
			OP_WR_rd <= #2 RD_OP_rd;
			OP_WR_ALUout <= #2 Next_ALUout;
			OP_WR_flag_register <= #2 Next_flag_register;
		end
	end

	always @(posedge clk) //Stage-3 
		if(!rst && OP_WR_rd != 5'd0)
			register_bank[OP_WR_rd] <= #2 OP_WR_ALUout;
endmodule
