// ============================================================================
// CASE 2 : Conventional 128x8 SRAM + MEMORY BANKING ONLY
// No clock gating (clk drives every bank directly, ungated), no power
// gating, no operand isolation, no data gating, no read-before-write,
// no FSM, no AAPM.
// ============================================================================

module sram_bank128 #(
    parameter BANK_DEPTH  = 32,
    parameter WIDTH       = 8,
    parameter BANK_ADDR_W = 5
) (
    input  wire                     clk,
    input  wire                     bank_we,
    input  wire [BANK_ADDR_W-1:0]   addr,
    input  wire [WIDTH-1:0]         wdata,
    output wire [WIDTH-1:0]         rdata_comb
);
    reg [WIDTH-1:0] mem [0:BANK_DEPTH-1];
    integer k;
    initial begin
        for (k = 0; k < BANK_DEPTH; k = k + 1)
            mem[k] = {WIDTH{1'b0}};
    end

    assign rdata_comb = mem[addr];

    // Plain clk -- NOT gated. Only the bank whose bank_we is asserted
    // ever updates; the other three banks simply don't toggle this cycle.
    always @(posedge clk) begin
        if (bank_we)
            mem[addr] <= wdata;
    end
endmodule


module sram_128x8_case2_banking (
    input  wire        clk,
    input  wire        reset,
    input  wire        chip_enable,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [6:0]  address,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    localparam NUM_BANKS   = 4;
    localparam BANK_DEPTH  = 32;   // 4 x 32 = 128 locations
    localparam BANK_ADDR_W = 5;    // log2(32)
    localparam BANK_SEL_W  = 2;    // log2(4)

    // ------------------------------------------------------------------
    // MEMORY BANKING -- the ONLY power optimization technique in this
    // case. address[6:5] selects one of 4 banks; address[4:0] is the
    // row inside that bank. Only the selected bank's write enable is
    // ever asserted, so only that bank's array actually switches.
    // ------------------------------------------------------------------
    wire [BANK_SEL_W-1:0]  bank_sel = address[6:5];
    wire [BANK_ADDR_W-1:0] row_addr = address[4:0];

    wire [7:0] bank_rdata [0:NUM_BANKS-1];
    wire       bank_we    [0:NUM_BANKS-1];

    genvar b;
    generate
        for (b = 0; b < NUM_BANKS; b = b + 1) begin : BANK_GEN
            assign bank_we[b] = chip_enable && write_enable &&
                                 (bank_sel == b[BANK_SEL_W-1:0]);

            sram_bank128 #(
                .BANK_DEPTH  (BANK_DEPTH),
                .WIDTH       (8),
                .BANK_ADDR_W (BANK_ADDR_W)
            ) u_bank (
                .clk        (clk),
                .bank_we    (bank_we[b]),
                .addr       (row_addr),
                .wdata      (din),
                .rdata_comb (bank_rdata[b])
            );
        end
    endgenerate

    wire [7:0] rdata_comb = bank_rdata[bank_sel];

    // Output register -- plain clk, same timing as the conventional design
    always @(posedge clk or posedge reset) begin
        if (reset)
            dout <= 8'h00;
        else if (chip_enable && read_enable)
            dout <= rdata_comb;
    end

endmodule
