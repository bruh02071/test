// tb_riscv_core.v - Self-checking testbench
`timescale 1ns/1ps
`include "define.v"

module tb_riscv_core;
    reg clk = 0, rst_n = 0;
    integer errors = 0;

    riscv_core #(.XLEN(32), .RESET_VECTOR(32'h0)) dut (
        .clk(clk), .rst_n(rst_n)
    );

    always #5 clk = ~clk;   // 100 MHz

    // ---- helper to write a hex instruction word ----
    task load_instr(input integer idx, input [31:0] word);
        begin dut.u_imem.mem[idx] = word; end
    endtask

    integer k;
    initial begin
        // zero memories
        for (k = 0; k < 1024; k = k + 1) begin
            dut.u_imem.mem[k] = 32'h00000013; // NOP (addi x0,x0,0)
            dut.u_dmem.mem[k] = 32'h0;
        end

        // ---- Program (word index = byte addr/4) ----
        // 0: addi x1, x0, 10       -> x1 = 10
        load_instr(0, 32'h00A00093);
        // 1: addi x2, x0, 20       -> x2 = 20
        load_instr(1, 32'h01400113);
        // 2: add  x3, x1, x2       -> x3 = 30  (forward x1,x2 from prior)
        load_instr(2, 32'h002081B3);
        // 3: sub  x4, x2, x1       -> x4 = 10
        load_instr(3, 32'h40110233);
        // 4: or   x5, x1, x2       -> x5 = 30 (0x1E)
        load_instr(4, 32'h0020E2B3);
        // 5: and  x6, x3, x2       -> x6 = 20 (0x14)
        load_instr(5, 32'h0021F333);
        // 6: sw   x3, 0(x0)        -> mem[0] = 30
        load_instr(6, 32'h00302023);
        // 7: lw   x7, 0(x0)        -> x7 = 30  (load)
        load_instr(7, 32'h00002383);
        // 8: add  x8, x7, x1       -> x8 = 40  (load-use stall on x7)
        load_instr(8, 32'h00138433);
        // 9: beq  x3, x5, +8       -> taken (30==30), skip instr 10
        load_instr(9, 32'h00518463);
        // 10: addi x9, x0, 99      -> SKIPPED (flushed)
        load_instr(10, 32'h06300493);
        // 11: addi x10, x0, 7      -> x10 = 7  (branch target)
        load_instr(11, 32'h00700513);

        // reset
        repeat (2) @(negedge clk);
        rst_n = 1;

        // run enough cycles for the pipeline to drain
        repeat (40) @(negedge clk);

        // ---- Checks ----
        check_reg(1, 32'd10);
        check_reg(2, 32'd20);
        check_reg(3, 32'd30);
        check_reg(4, 32'd10);
        check_reg(5, 32'd30);
        check_reg(6, 32'd20);
        check_reg(7, 32'd30);
        check_reg(8, 32'd40);   // proves load-use stall + forwarding
        check_reg(9, 32'd0);    // proves branch flush (never wrote 99)
        check_reg(10, 32'd7);   // proves branch target executed
        check_mem(0, 32'd30);   // proves store

        if (errors == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: %0d TEST(S) FAILED", errors);
        $finish;
    end

    task check_reg(input [4:0] idx, input [31:0] exp);
        begin
            if (dut.u_rf.regs[idx] !== exp) begin
                $display("FAIL: x%0d = 0x%08h, expected 0x%08h",
                         idx, dut.u_rf.regs[idx], exp);
                errors = errors + 1;
            end else
                $display("PASS: x%0d = %0d", idx, exp);
        end
    endtask

    task check_mem(input integer idx, input [31:0] exp);
        begin
            if (dut.u_dmem.mem[idx] !== exp) begin
                $display("FAIL: mem[%0d] = 0x%08h, expected 0x%08h",
                         idx, dut.u_dmem.mem[idx], exp);
                errors = errors + 1;
            end else
                $display("PASS: mem[%0d] = %0d", idx, exp);
        end
    endtask
endmodule

