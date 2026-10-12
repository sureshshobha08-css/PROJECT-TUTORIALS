
module data_gate #(
    parameter WIDTH = 8
) (
    input  wire               gate_enable,
    input  wire [WIDTH-1:0]   data_in,
    output wire [WIDTH-1:0]   data_out
);
    // Prevents a data bus from toggling into the compare/write logic
    // whenever a write is not actually requested.
    assign data_out = gate_enable ? data_in : {WIDTH{1'b0}};
endmodule


module sram_128x8_case5_datagate_rbw (
    input  wire        clk,
    input  wire        reset,
    input  wire        chip_enable,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [6:0]  address,
    input  wire [7:0]  din,
    input  wire [7:0]  mask,      // 1 = update this bit, 0 = keep old bit
    output reg  [7:0]  dout
);

    reg [7:0] mem [0:127];
    integer k;
    initial begin
        for (k = 0; k < 128; k = k + 1)
            mem[k] = 8'h00;
    end

    // Combinational read of the currently-addressed location; needed by
    // the data masking merge and the read-before-write compare below,
    // and also used for ordinary reads, exactly as in the conventional
    // design.
    wire [7:0] old_data = mem[address];

    // ------------------------------------------------------------------
    // DATA GATING -- the input data bus and the mask bus only reach the
    // masking/compare/write logic while a write is actually requested;
    // otherwise both are forced to 0, so random/unrelated din or mask
    // activity on idle or read cycles cannot toggle that logic.
    // ------------------------------------------------------------------
    wire write_requested = chip_enable && write_enable;

    wire [7:0] din_gated;
    wire [7:0] mask_gated;

    data_gate #(.WIDTH(8)) u_dgate_din (
        .gate_enable (write_requested),
        .data_in     (din),
        .data_out    (din_gated)
    );

    data_gate #(.WIDTH(8)) u_dgate_mask (
        .gate_enable (write_requested),
        .data_in     (mask),
        .data_out    (mask_gated)
    );

    // ------------------------------------------------------------------
    // DATA MASKING -- only the bits selected by mask_gated are taken
    // from din_gated; every other bit keeps its old stored value. This
    // is a bit-level merge, done BEFORE the read-before-write compare,
    // so RBW only ever reacts to the bits that were actually masked in.
    // ------------------------------------------------------------------
    wire [7:0] masked_new_data = (din_gated & mask_gated) | (old_data & ~mask_gated);

    // ------------------------------------------------------------------
    // READ-BEFORE-WRITE -- the masked result is compared against the
    // data already stored at that address; the array is only written
    // if the merged value would actually change.
    // ------------------------------------------------------------------
    wire data_changed = (masked_new_data != old_data);
    wire do_write     = write_requested && data_changed;

    always @(posedge clk) begin
        if (do_write)
            mem[address] <= masked_new_data;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            dout <= 8'h00;
        else if (chip_enable && read_enable)
            dout <= old_data;
    end

endmodule
