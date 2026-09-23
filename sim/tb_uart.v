`timescale 1ns/1ps
module tb_uart;
    reg clk = 0;
    reg rst_n = 0;
    always #10 clk = ~clk;

    localparam [15:0] DIV = 16'd8;

    reg start = 0;
    reg [7:0] txdata = 8'hA5;
    wire busy, tx, ready, overrun;
    wire [7:0] rxdata;

    uart_tx u_tx (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .div(DIV), .start(start), .data(txdata),
        .busy(busy), .tx(tx)
    );
    uart_rx u_rx (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .div(DIV), .rx(tx),
        .data(rxdata), .ready(ready), .overrun(overrun),
        .ready_clr(1'b0)
    );

    integer guard;
    initial begin
        repeat (8) @(posedge clk);
        rst_n = 1;
        repeat (4) @(posedge clk);
        start = 1; @(posedge clk); start = 0;
        guard = 0;
        while (!ready && guard < 5000) begin
            @(posedge clk);
            guard = guard + 1;
        end
        if (!ready || rxdata !== 8'hA5) begin
            $display("FAIL uart loopback got %02x ready=%0d", rxdata, ready);
            $finish(1);
        end
        $display("PASS tb_uart");
        $finish(0);
    end
endmodule
