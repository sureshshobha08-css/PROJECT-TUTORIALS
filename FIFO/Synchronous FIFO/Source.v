// Synchronous FIFO: 16 locations x 8 bits, single clock, active-low reset
module sync_fifo (
    input            clk,
    input            rst_n,     // active-low reset
    input            wr_en,     // write request
    input            rd_en,     // read request
    input      [7:0] din,       // data in
    output reg [7:0] dout,      // data out
    output           full,
    output           empty
);

    reg [7:0] mem [0:15];       // memory: 16 words of 8 bits
    reg [3:0] wr_ptr;           // where the next write goes
    reg [3:0] rd_ptr;           // where the next read comes from
    reg [4:0] count;            // number of words stored (0 to 16)

    assign full  = (count == 16);
    assign empty = (count == 0);

    wire do_write = wr_en && !full;     // write allowed only if not full
    wire do_read  = rd_en && !empty;    // read allowed only if not empty

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 0;
        end
        else begin
            // Write: store data, move write pointer (15 + 1 wraps to 0)
            if (do_write) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1;
            end

            // Read: fetch data, move read pointer (15 + 1 wraps to 0)
            if (do_read) begin
                dout   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end

            // Count: +1 for write only, -1 for read only, same otherwise
            if (do_write && !do_read)
                count <= count + 1;
            else if (do_read && !do_write)
                count <= count - 1;
        end
    end

endmodule
