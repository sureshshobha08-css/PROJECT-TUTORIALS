module sram_array #(
    parameter WIDTH = 8,
    parameter DEPTH = 64,
    parameter ADDR_W = 6
)(
    input                       clk,
    input                       chip_enable,
    input                       write_enable,
    input      [ADDR_W-1:0] address,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk)
    begin
        if (chip_enable)
        begin
            if (write_enable)
                mem[address] <= din;
            else
                dout <= mem[address];
        end
    end

endmodule

module conventional_sram #(
    parameter WIDTH = 8,
    parameter DEPTH = 64,
    parameter ADDR_W= 6
)(
    input                       clk,
    input                       chip_enable,
    input                       write_enable,
    input      [ADDR_W-1:0] address,
    input      [WIDTH-1:0] din,
    output     [WIDTH-1:0] dout
);

    sram_array #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W)
    ) sram_inst (
        .clk(clk),
        .chip_enable(chip_enable),
        .write_enable(write_enable),
        .address(address),
        .din(din),
        .dout(dout)
    );

endmodule
