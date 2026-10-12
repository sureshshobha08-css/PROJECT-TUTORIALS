
module clock_gate (
    input  wire clk,
    input  wire enable,
    output wire gated_clk
);
    // Transparent latch: samples 'enable' only while clk is low, so the
    // AND gate below can never glitch the output clock.
    reg latch_enable;
    always @(*) begin
        if (!clk)
            latch_enable = enable;
    end
    assign gated_clk = clk & latch_enable;
endmodule


module sram_128x8_case1_clockgate (
    input  wire        clk,
    input  wire        reset,
    input  wire        chip_enable,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [6:0]  address,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    // Conventional 128 x 8 storage array
    reg [7:0] mem [0:127];
    integer k;
    initial begin
        for (k = 0; k < 128; k = k + 1)
            mem[k] = 8'h00;
    end

    // ------------------------------------------------------------------
    // CLOCK GATING -- the ONLY power optimization technique in this case.
    // The clock that drives the write port and the output register is
    // gated so it only toggles during an actual chip access
    // (chip_enable && (read_enable || write_enable)); it stays flat the
    // rest of the time.
    // ------------------------------------------------------------------
    wire access_active = chip_enable && (read_enable || write_enable);
    wire gated_clk;
    clock_gate u_cg (
        .clk       (clk),
        .enable    (access_active),
        .gated_clk (gated_clk)
    );

    // Asynchronous (combinational) read path -- conventional, unchanged
    wire [7:0] rdata_comb = mem[address];

    // Synchronous write path -- now clocked ONLY by gated_clk
    always @(posedge gated_clk) begin
        if (chip_enable && write_enable)
            mem[address] <= din;
    end

    // Output register -- also clocked ONLY by gated_clk
    always @(posedge gated_clk or posedge reset) begin
        if (reset)
            dout <= 8'h00;
        else if (chip_enable && read_enable)
            dout <= rdata_comb;
    end

endmodule


