
module tb_case5_datagate_rbw;

    reg         clk;
    reg         reset;
    reg         chip_enable;
    reg         read_enable;
    reg         write_enable;
    reg  [6:0]  address;
    reg  [7:0]  din;
    reg  [7:0]  mask;
    wire [7:0]  dout;

    sram_128x8_case5_datagate_rbw dut (
        .clk          (clk),
        .reset        (reset),
        .chip_enable  (chip_enable),
        .read_enable  (read_enable),
        .write_enable (write_enable),
        .address      (address),
        .din          (din),
        .mask         (mask),
        .dout         (dout)
    );

    always #5 clk = ~clk;

    task do_write(input [6:0] a, input [7:0] d);
        begin
            @(negedge clk);
            chip_enable = 1; write_enable = 1; read_enable = 0;
            address = a; din = d; mask = 8'hFF;   // full-byte update, same as other cases
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
        $dumpfile("tb_case5_datagate_rbw.vcd");
        $dumpvars(0, tb_case5_datagate_rbw);

        clk = 0; reset = 1;
        chip_enable = 0; read_enable = 0; write_enable = 0;
        address = 0; din = 0; mask = 8'h00;

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

        // Note: this pattern (write 5A, rewrite same 5A, then write
        // different 5B) is what exercises read-before-write: the second
        // write is skipped internally by the DUT because data_changed=0.
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
        $display("Case 5 (Data Gating + Read-Before-Write) stimulus complete.");
        $finish;
    end

endmodule
