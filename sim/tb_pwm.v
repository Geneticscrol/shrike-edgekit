`timescale 1ns/1ps
module tb_pwm;
    reg clk = 0;
    reg rst_n = 0;
    always #10 clk = ~clk;

    wire pwm;
    pwm_ch dut (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .period(16'd10), .duty(16'd4), .pwm(pwm)
    );

    integer i, high, low;
    initial begin
        high = 0;
        low = 0;
        repeat (8) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            if (pwm) high = high + 1;
            else     low  = low + 1;
        end
        $display("pwm high=%0d low=%0d", high, low);
        if (high < 30 || high > 50) begin
            $display("FAIL duty window");
            $finish(1);
        end
        $display("PASS tb_pwm");
        $finish(0);
    end
endmodule
