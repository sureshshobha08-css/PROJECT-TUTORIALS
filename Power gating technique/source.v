
module power_switch (
    input  wire power_enable,
    input  wire in_signal,
    output wire out_signal
);
    // Models a simple header/footer sleep-transistor cell: the control
    // signal only reaches the memory array while the block is powered.
    assign out_signal = power_enable & in_signal;
endmodule


module sram_128x8_case3_powergate (
    input  wire        clk,
    input  wire        reset,
    input  wire        chip_enable,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [6:0]  address,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    reg [7:0] mem [0:127];
    integer k;
    initial begin
        for (k = 0; k < 128; k = k + 1)
            mem[k] = 8'h00;
    end

    // ------------------------------------------------------------------
    // POWER GATING -- the ONLY power optimization technique in this case.
    // power_enable represents the header/footer switch state: the array
    // is only powered while the chip is enabled. The write and read
    // enables that reach the array are routed through power_switch
    // cells, and the output is forced to a defined 0 whenever the block
    // is unpowered (no retention is implied or added).
    // ------------------------------------------------------------------
    wire power_enable = chip_enable;

    wire array_write_enable;
    wire array_read_enable;

    power_switch u_ps_we (.power_enable(power_enable), .in_signal(write_enable), .out_signal(array_write_enable));
    power_switch u_ps_re (.power_enable(power_enable), .in_signal(read_enable),  .out_signal(array_read_enable));

    wire [7:0] rdata_comb = mem[address];

    always @(posedge clk) begin
        if (array_write_enable)
            mem[address] <= din;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            dout <= 8'h00;
        else if (array_read_enable)
            dout <= rdata_comb;
        else if (!power_enable)
            dout <= 8'h00;   // block unpowered -> defined 0, no retained value
    end

endmodule
