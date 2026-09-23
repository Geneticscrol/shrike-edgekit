// 8N1 receiver, 1x sampling at the baud midpoint.
module uart_rx (
    input        clk,
    input        rst_n,
    input        en,
    input [15:0] div,
    input        rx,
    output reg [7:0] data,
    output reg       ready,
    output reg       overrun,
    input            ready_clr
);
    localparam ST_IDLE  = 2'd0;
    localparam ST_START = 2'd1;
    localparam ST_DATA  = 2'd2;
    localparam ST_STOP  = 2'd3;

    wire rx_s;
    sync2 u_rxsync (
        .clk(clk), .rst_n(rst_n), .din(rx), .dout(rx_s)
    );

    reg [1:0]  st;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  sh;

    wire [15:0] baud_div = (div == 16'd0) ? 16'd1 : div;
    wire [15:0] half     = {1'b0, baud_div[15:1]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= ST_IDLE;
            baud_cnt <= 16'd0;
            bit_idx  <= 3'd0;
            sh       <= 8'd0;
            data     <= 8'd0;
            ready    <= 1'b0;
            overrun  <= 1'b0;
        end else begin
            if (ready_clr)
                ready <= 1'b0;
            if (!en) begin
                st <= ST_IDLE;
            end else begin
                case (st)
                    ST_IDLE: begin
                        if (rx_s == 1'b0) begin
                            baud_cnt <= (half == 16'd0) ? 16'd0 : (half - 16'd1);
                            st       <= ST_START;
                        end
                    end
                    ST_START: begin
                        if (baud_cnt == 16'd0) begin
                            if (rx_s == 1'b0) begin
                                baud_cnt <= baud_div - 16'd1;
                                bit_idx  <= 3'd0;
                                st       <= ST_DATA;
                            end else
                                st <= ST_IDLE;
                        end else
                            baud_cnt <= baud_cnt - 16'd1;
                    end
                    ST_DATA: begin
                        if (baud_cnt == 16'd0) begin
                            sh       <= {rx_s, sh[7:1]};
                            baud_cnt <= baud_div - 16'd1;
                            if (bit_idx == 3'd7)
                                st <= ST_STOP;
                            else
                                bit_idx <= bit_idx + 3'd1;
                        end else
                            baud_cnt <= baud_cnt - 16'd1;
                    end
                    ST_STOP: begin
                        if (baud_cnt == 16'd0) begin
                            if (ready)
                                overrun <= 1'b1;
                            data  <= sh;
                            ready <= 1'b1;
                            st    <= ST_IDLE;
                        end else
                            baud_cnt <= baud_cnt - 16'd1;
                    end
                    default: st <= ST_IDLE;
                endcase
            end
        end
    end
endmodule
