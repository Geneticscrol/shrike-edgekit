// SPI Mode 0 slave. 16 clocks per access while CS_N is low.
// Frame: {W, ADDR[6:0], DATA[7:0]}, MSB first.
module link6_spi_slave (
    input        clk,
    input        rst_n,
    input        sck,
    input        cs_n,
    input        mosi,
    output       miso,
    output       miso_oe,
    output       wr_stb,
    output       rd_stb,
    output [6:0] addr,
    output [7:0] wdata,
    input  [7:0] rdata
);
    wire sck_s, cs_s, mosi_s;
    sync2 #(.WIDTH(3)) u_sync (
        .clk  (clk),
        .rst_n(rst_n),
        .din  ({sck, cs_n, mosi}),
        .dout ({sck_s, cs_s, mosi_s})
    );

    reg sck_d, cs_d;
    wire sck_rise = sck_s & ~sck_d;
    wire cs_fall  = ~cs_s & cs_d;
    wire cs_high  = cs_s;

    reg        active;
    reg [3:0]  bitcnt;
    reg [15:0] rx;
    reg [7:0]  tx;
    reg        wr_q, rd_q;
    reg [6:0]  addr_q;
    reg [7:0]  wdata_q;
    reg        miso_q;

    assign wr_stb  = wr_q;
    assign rd_stb  = rd_q;
    assign addr    = addr_q;
    assign wdata   = wdata_q;
    assign miso    = miso_q;
    assign miso_oe = active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_d   <= 1'b0;
            cs_d    <= 1'b1;
            active  <= 1'b0;
            bitcnt  <= 4'd0;
            rx      <= 16'd0;
            tx      <= 8'd0;
            wr_q    <= 1'b0;
            rd_q    <= 1'b0;
            addr_q  <= 7'd0;
            wdata_q <= 8'd0;
            miso_q  <= 1'b0;
        end else begin
            sck_d <= sck_s;
            cs_d  <= cs_s;
            wr_q  <= 1'b0;
            rd_q  <= 1'b0;

            if (cs_fall) begin
                active <= 1'b1;
                bitcnt <= 4'd0;
                rx     <= 16'd0;
                tx     <= 8'd0;
                miso_q <= 1'b0;
            end else if (cs_high) begin
                active <= 1'b0;
            end else if (active && sck_rise) begin
                rx <= {rx[14:0], mosi_s};

                if (bitcnt == 4'd7) begin
                    addr_q <= {rx[5:0], mosi_s};
                    rd_q   <= ~rx[6];
                end

                if (bitcnt == 4'd8)
                    tx <= rdata;

                if (bitcnt == 4'd15) begin
                    wdata_q <= {rx[6:0], mosi_s};
                    addr_q  <= rx[13:7];
                    wr_q    <= rx[14];
                end

                bitcnt <= bitcnt + 4'd1;
            end

            if (active && sck_rise && bitcnt >= 4'd8 && bitcnt < 4'd16) begin
                if (bitcnt == 4'd8)
                    miso_q <= rdata[7];
                else
                    miso_q <= tx[7];
                if (bitcnt > 4'd8)
                    tx <= {tx[6:0], 1'b0};
            end
        end
    end
endmodule
