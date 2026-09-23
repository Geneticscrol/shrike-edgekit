// 8N1 transmitter. div = SYS_HZ / baud. Starts when start pulses and data is valid.
module uart_tx (
    input        clk,
    input        rst_n,
    input        en,
    input [15:0] div,
    input        start,
    input  [7:0] data,
    output       busy,
    output reg   tx
);
    localparam ST_IDLE  = 2'd0;
    localparam ST_START = 2'd1;
    localparam ST_DATA  = 2'd2;
    localparam ST_STOP  = 2'd3;

    reg [1:0]  st;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  sh;

    wire [15:0] baud_div = (div == 16'd0) ? 16'd1 : div;
    assign busy = (st != ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= ST_IDLE;
            baud_cnt <= 16'd0;
            bit_idx  <= 3'd0;
            sh       <= 8'd0;
            tx       <= 1'b1;
        end else if (!en) begin
            st       <= ST_IDLE;
            tx       <= 1'b1;
        end else begin
            case (st)
                ST_IDLE: begin
                    tx <= 1'b1;
                    if (start) begin
                        sh       <= data;
                        baud_cnt <= baud_div - 16'd1;
                        st       <= ST_START;
                        tx       <= 1'b0;
                    end
                end
                ST_START: begin
                    if (baud_cnt == 16'd0) begin
                        baud_cnt <= baud_div - 16'd1;
                        bit_idx  <= 3'd0;
                        tx       <= sh[0];
                        sh       <= {1'b0, sh[7:1]};
                        st       <= ST_DATA;
                    end else
                        baud_cnt <= baud_cnt - 16'd1;
                end
                ST_DATA: begin
                    if (baud_cnt == 16'd0) begin
                        baud_cnt <= baud_div - 16'd1;
                        if (bit_idx == 3'd7) begin
                            tx <= 1'b1;
                            st <= ST_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                            tx      <= sh[0];
                            sh      <= {1'b0, sh[7:1]};
                        end
                    end else
                        baud_cnt <= baud_cnt - 16'd1;
                end
                ST_STOP: begin
                    tx <= 1'b1;
                    if (baud_cnt == 16'd0)
                        st <= ST_IDLE;
                    else
                        baud_cnt <= baud_cnt - 16'd1;
                end
                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
