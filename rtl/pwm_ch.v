// Single PWM channel. period/duty in fabric clocks.
// High while count < duty. period==0 is treated as 1.
module pwm_ch (
    input        clk,
    input        rst_n,
    input        en,
    input [15:0] period,
    input [15:0] duty,
    output reg   pwm
);
    reg [15:0] cnt;
    wire [15:0] per = (period == 16'd0) ? 16'd1 : period;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 16'd0;
            pwm <= 1'b0;
        end else if (!en) begin
            cnt <= 16'd0;
            pwm <= 1'b0;
        end else begin
            if (cnt >= (per - 16'd1))
                cnt <= 16'd0;
            else
                cnt <= cnt + 16'd1;
            pwm <= (cnt < duty);
        end
    end
endmodule
