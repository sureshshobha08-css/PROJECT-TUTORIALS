
module operand_isolation #(
    parameter WIDTH = 8
) (
    input  wire               isolate_enable,
    input  wire [WIDTH-1:0]   data_in,
    output wire [WIDTH-1:0]   data_out
);
    // Forces the bus to a constant 0 whenever there is no valid access,
    // instead of letting it keep toggling into the array/decoder logic.
    assign data_out = isolate_enable ? data_in : {WIDTH{1'b0}};
endmodule


module sram_128x8_case4_opiso (
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
    // OPERAND ISOLATION -- the ONLY power optimization technique in this
    // case. The address bus and the data-in bus are isolated (forced to
    // 0) whenever there is no valid chip access, so they stop toggling
    // into the memory array and its address decoder on idle cycles.
    // Whenever an access IS valid, the isolated signals equal the
    // original ones exactly, so functionality is unchanged.
    // ------------------------------------------------------------------
    wire access_valid = chip_enable && (read_enable || write_enable);

    wire [6:0] address_isolated;
    wire [7:0] din_isolated;

    operand_isolation #(.WIDTH(7)) u_iso_addr (
        .isolate_enable (access_valid),
        .data_in        (address),
        .data_out       (address_isolated)
    );

    operand_isolation #(.WIDTH(8)) u_iso_din (
        .isolate_enable (access_valid),
        .data_in        (din),
        .data_out       (din_isolated)
    );

    wire [7:0] rdata_comb = mem[address_isolated];

    always @(posedge clk) begin
        if (chip_enable && write_enable)
            mem[address_isolated] <= din_isolated;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            dout <= 8'h00;
        else if (chip_enable && read_enable)
            dout <= rdata_comb;
    end

endmodule
