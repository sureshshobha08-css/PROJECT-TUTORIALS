module tb_conventional_sram;

parameter WIDTH = 8;
parameter DEPTH = 64;
parameter ADDR_W = 6;

reg clk;
reg chip_enable;
reg write_enable;
reg [ADDR_W-1:0] address;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] dout;

conventional_sram #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) DUT (
    .clk(clk),
    .chip_enable(chip_enable),
    .write_enable(write_enable),
    .address(address),
    .din(din),
    .dout(dout)
);

always #5 clk = ~clk;

initial
begin
    clk  = 0;
    chip_enable   = 0;
    write_enable   = 0;
    address = 0;
    din  = 0;

    #10;

    // Write Operation 1
    chip_enable   = 1;
    write_enable   = 1;
    address = 9'd0;
    din  = 8'hA5;
    #10;

    // Read Operation 1
    write_enable   = 0;
    address = 9'd0;
    #10;

    // Write Operation 2
    write_enable   = 1;
    address = 9'd1;
    din  = 8'h22;
    #10;

    // Write Operation 3
    address = 9'd3;
    din  = 8'hFF;
    #10;

    // Chip Disable
    chip_enable = 0;
    #20;

    // Enable Again
    chip_enable = 1;

    // Write Operation 4
    write_enable   = 1;
    address = 9'd3;
    din  = 8'h00;
    #10;

    // Read Operation 2
    write_enable   = 0;
    address = 9'd3;
    #10;

    // Write Operation 5
    write_enable  = 1;
    address = 9'd4;
    din  = 8'h5A;
    #10;

    // Write Operation 6
    address = 9'd4;
    din  = 8'h5A;
    #10;

    // Write Operation 7
    address = 9'd4;
    din  = 8'h5B;
    #10;

    // Write Operation 8
    address = 9'd5;
    din  = 8'h11;
    #10;

    // Write Operation 9
    address = 9'd15;
    din = 8'h22;
    #10;

    // Write Operation 10
    address = 9'd25;
    din = 8'h33;
    #10;

    // Write Operation 11
    address = 9'd35;
    din = 8'h44;
    #10;

    // Read Operation 3
    write_enable   = 0;
    address = 9'd5;
    #10;

    // Read Operation 4
    address = 9'd15;
    #10;

    // Read Operation 5
    address = 9'd25;
    #10;

    // Read Operation 6
    address = 9'd35;
    #10;

    $finish;
end

initial
begin
    $monitor("Time=%0t CHIP_ENABLE=%b WRITE_ENABLE=%b ADDRESS=%d DIN=%h DOUT=%h",
              $time,chip_enable,write_enable,address,din,dout);
end

endmodule
