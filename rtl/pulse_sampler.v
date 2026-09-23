// One-shot pulse/period capture on a synchronized input.
// ARM (or TRIG) waits for a rising edge, measures high width, then waits
// for the next rising edge to close the period.
module pulse_sampler (
    input         clk,
    input         rst_n,
    input         en,
    input         din,
    input         arm,
    input         soft_rst,
    output        armed,
    output        ready,
    output [15:0] width,
    output [15:0] period
);
    wire din_s;
    sync2 u_sync (
        .clk(clk), .rst_n(rst_n), .din(din), .dout(din_s)
    );

    reg din_d;
    wire rise =  din_s & ~din_d;
    wire fall = ~din_s &  din_d;

    localparam ST_IDLE   = 2'd0;
    localparam ST_WAIT_R = 2'd1;
    localparam ST_HIGH   = 2'd2;
    localparam ST_WAIT_P = 2'd3;

    reg [1:0]  st;
    reg [15:0] wcnt, pcnt;
    reg [15:0] width_q, period_q;
    reg        ready_q;

    assign width  = width_q;
    assign period = period_q;
    assign ready  = ready_q;
    assign armed  = (st != ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_d    <= 1'b0;
            st       <= ST_IDLE;
            wcnt     <= 16'd0;
            pcnt     <= 16'd0;
            width_q  <= 16'd0;
            period_q <= 16'd0;
            ready_q  <= 1'b0;
        end else begin
            din_d <= din_s;
            if (soft_rst || !en) begin
                st      <= ST_IDLE;
                ready_q <= 1'b0;
            end else begin
                case (st)
                    ST_IDLE: begin
                        if (arm) begin
                            ready_q <= 1'b0;
                            wcnt    <= 16'd0;
                            pcnt    <= 16'd0;
                            st      <= ST_WAIT_R;
                        end
                    end
                    ST_WAIT_R: begin
                        if (rise) begin
                            wcnt <= 16'd1;
                            pcnt <= 16'd1;
                            st   <= ST_HIGH;
                        end
                    end
                    ST_HIGH: begin
                        if (wcnt != 16'hFFFF)
                            wcnt <= wcnt + 16'd1;
                        if (pcnt != 16'hFFFF)
                            pcnt <= pcnt + 16'd1;
                        if (fall) begin
                            width_q <= wcnt;
                            st      <= ST_WAIT_P;
                        end
                    end
                    ST_WAIT_P: begin
                        if (pcnt != 16'hFFFF)
                            pcnt <= pcnt + 16'd1;
                        if (rise) begin
                            period_q <= pcnt;
                            ready_q  <= 1'b1;
                            st       <= ST_IDLE;
                        end
                    end
                    default: st <= ST_IDLE;
                endcase
            end
        end
    end
endmodule
