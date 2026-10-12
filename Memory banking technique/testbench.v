// ============================================================================
// Testbench for CASE 2 : Memory Banking ONLY
// Identical stimulus to Case 1 -- only the DUT instance type changes.
// ============================================================================

module tb_case2_banking;

    reg         clk;
    reg         reset;
    reg         chip_enable;
    reg         read_enable;
    reg         write_enable;
    reg  [6:0]  address;
    reg  [7:0]  din;
    wire [7:0]  dout;

    sram_128x8_case2_banking dut (
        .clk          (clk),
        .reset        (reset),
        .chip_enable  (chip_enable),
        .read_enable  (read_enable),
        .write_enable (write_enable),
        .address      (address),
        .din          (din),
        .dout         (dout)
    );

    always #5 clk = ~clk;

    task do_write(input [6:0] a, input [7:0] d);
        begin
            @(negedge clk);
            chip_enable = 1; write_enable = 1; read_enable = 0;
            address = a; din = d;
            @(negedge clk);
            chip_enable = 0; write_enable = 0;
        end
    endtask

    task do_read(input [6:0] a);
        begin
            @(negedge clk);
            chip_enable = 1; read_enable = 1; write_enable = 0;
            address = a;
            @(negedge clk);
            chip_enable = 0; read_enable = 0;
        end
    endtask

    task idle(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_case2_banking.vcd");
        $dumpvars(0, tb_case2_banking);

        clk = 0; reset = 1;
        chip_enable = 0; read_enable = 0; write_enable = 0;
        address = 0; din = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // ================= COMMON TEST SEQUENCE (identical in all 5 cases) =================
        do_write(7'h00, 8'hA5);
        do_read (7'h00);

        idle(9);
        idle(2);
        idle(5);
        idle(2);
        idle(3);

        do_write(7'h01, 8'h22);

        do_write(7'h03, 8'hFF);
        do_write(7'h03, 8'h00);
        do_read (7'h03);

        do_write(7'h04, 8'h5A);
        do_write(7'h04, 8'h5A);
        do_write(7'h04, 8'h5B);

        do_write(7'h05, 8'h11);
        do_write(7'h25, 8'h22);
        do_write(7'h45, 8'h33);
        do_write(7'h65, 8'h44);
        do_read (7'h05);
        do_read (7'h25);
        do_read (7'h45);
        do_read (7'h65);

        #20;
        $display("Case 2 (Memory Banking) stimulus complete.");
        $finish;
    end

endmodule
