`timescale 1ns/1ps
module sync_fifo_tb;

reg clk, rst_n;
reg wr_en, rd_en;
reg [7:0] din;
wire [7:0] dout;
wire full, empty;

sync_fifo uut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .din(din),
    .dout(dout),
    .full(full),
    .empty(empty)
);

initial clk = 0;
always #5 clk = ~clk;

initial
begin
    rst_n = 0;              // active-low reset
    wr_en = 0;
    rd_en = 0;
    din = 0;

    #20 rst_n = 1;

    // Write 3 words
    #5 wr_en = 1;
    din = 8'hA5;

    #10 din = 8'h3C;
    #10 din = 8'hF0;

    #10 wr_en = 0;

    // Read 3 words
    #10 rd_en = 1;
    #30 rd_en = 0;

    // Write 16 words (FIFO becomes full)
    #10 wr_en = 1;
    din = 8'h01;

    #10 din = 8'h02;
    #10 din = 8'h03;
    #10 din = 8'h04;
    #10 din = 8'h05;
    #10 din = 8'h06;
    #10 din = 8'h07;
    #10 din = 8'h08;
    #10 din = 8'h09;
    #10 din = 8'h0A;
    #10 din = 8'h0B;
    #10 din = 8'h0C;
    #10 din = 8'h0D;
    #10 din = 8'h0E;
    #10 din = 8'h0F;
    #10 din = 8'h10;

    #10 wr_en = 0;

    // Read 16 words (FIFO becomes empty)
    #10 rd_en = 1;
    #160 rd_en = 0;

    #20 $finish;
end

initial
begin
  
    $monitor("Time=%0t din=%h dout=%h full=%b empty=%b",
             $time, din, dout, full, empty);
end

endmodule
