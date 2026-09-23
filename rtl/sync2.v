// Two-flop synchronizer. Width is a parameter so IRQ/TRIG and smp_in share it.
module sync2 #(
    parameter WIDTH = 1
) (
    input                  clk,
    input                  rst_n,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] mid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mid  <= {WIDTH{1'b0}};
            dout <= {WIDTH{1'b0}};
        end else begin
            mid  <= din;
            dout <= mid;
        end
    end
endmodule
