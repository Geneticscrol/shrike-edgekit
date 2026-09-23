// Memory-mapped register file for Link-6.
module regs (
    input        clk,
    input        rst_n,
    input        wr_stb,
    input        rd_stb,
    input  [6:0] addr,
    input  [7:0] wdata,
    output reg [7:0] rdata,
    input        uart_rx_ready,
    input        uart_tx_busy,
    input        uart_rx_overrun,
    input        smp_ready,
    input        smp_armed,
    input  [7:0] uart_rx_data,
    input [15:0] smp_width,
    input [15:0] smp_period,
    output       core_en,
    output       led_force,
    output       pwm_en,
    output       uart_en,
    output       smp_en,
    output [15:0] pwm_period,
    output [15:0] pwm_duty,
    output [15:0] uart_div,
    output       uart_tx_start,
    output [7:0] uart_tx_data,
    output       uart_rx_clr,
    output       smp_arm,
    output       smp_rst,
    output       smp_ready_clr,
    output [7:0] irq_mask,
    output [7:0] status
);
    localparam ID  = 8'hE6;
    localparam VER = 8'h10;
    localparam CAPS = 8'h07;

    reg [7:0]  ctrl;
    reg [7:0]  irq_mask_r;
    reg [15:0] pwm_period_r;
    reg [15:0] pwm_duty_r;
    reg [15:0] uart_div_r;
    reg [7:0]  uart_tx_r;
    reg        uart_tx_strobe;
    reg        uart_rx_clr_r;
    reg        smp_arm_r;
    reg        smp_rst_r;
    reg        smp_ready_clr_r;

    assign core_en      = ctrl[0];
    assign led_force    = ctrl[1];
    assign pwm_en       = ctrl[2];
    assign uart_en      = ctrl[3];
    assign smp_en       = ctrl[4];
    assign pwm_period   = pwm_period_r;
    assign pwm_duty     = pwm_duty_r;
    assign uart_div     = uart_div_r;
    assign uart_tx_start= uart_tx_strobe;
    assign uart_tx_data = uart_tx_r;
    assign uart_rx_clr  = uart_rx_clr_r;
    assign smp_arm      = smp_arm_r;
    assign smp_rst      = smp_rst_r;
    assign smp_ready_clr= smp_ready_clr_r;
    assign irq_mask     = irq_mask_r;

    assign status = {3'b000, smp_armed, smp_ready, uart_rx_overrun, uart_tx_busy, uart_rx_ready};

    always @(*) begin
        case (addr)
            7'h00: rdata = ID;
            7'h01: rdata = VER;
            7'h02: rdata = CAPS;
            7'h03: rdata = status;
            7'h04: rdata = irq_mask_r;
            7'h05: rdata = ctrl;
            7'h10: rdata = pwm_period_r[7:0];
            7'h11: rdata = pwm_period_r[15:8];
            7'h12: rdata = pwm_duty_r[7:0];
            7'h13: rdata = pwm_duty_r[15:8];
            7'h20: rdata = uart_div_r[7:0];
            7'h21: rdata = uart_div_r[15:8];
            7'h22: rdata = 8'h00;
            7'h23: rdata = uart_rx_data;
            7'h30: rdata = {6'b0, smp_armed, smp_ready};
            7'h31: rdata = smp_width[7:0];
            7'h32: rdata = smp_width[15:8];
            7'h33: rdata = smp_period[7:0];
            7'h34: rdata = smp_period[15:8];
            default: rdata = 8'h00;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl          <= 8'h01;
            irq_mask_r    <= 8'h09;
            pwm_period_r  <= 16'd1000;
            pwm_duty_r    <= 16'd500;
            uart_div_r    <= 16'd434;
            uart_tx_r     <= 8'd0;
            uart_tx_strobe<= 1'b0;
            uart_rx_clr_r <= 1'b0;
            smp_arm_r     <= 1'b0;
            smp_rst_r     <= 1'b0;
            smp_ready_clr_r <= 1'b0;
        end else begin
            uart_tx_strobe  <= 1'b0;
            uart_rx_clr_r   <= 1'b0;
            smp_arm_r       <= 1'b0;
            smp_rst_r       <= 1'b0;
            smp_ready_clr_r <= 1'b0;

            if (rd_stb && addr == 7'h23)
                uart_rx_clr_r <= 1'b1;
            if (rd_stb && addr == 7'h34)
                smp_ready_clr_r <= 1'b1;

            if (wr_stb) begin
                case (addr)
                    7'h04: irq_mask_r   <= wdata;
                    7'h05: ctrl         <= wdata;
                    7'h10: pwm_period_r[7:0]  <= wdata;
                    7'h11: pwm_period_r[15:8] <= wdata;
                    7'h12: pwm_duty_r[7:0]    <= wdata;
                    7'h13: pwm_duty_r[15:8]   <= wdata;
                    7'h20: uart_div_r[7:0]    <= wdata;
                    7'h21: uart_div_r[15:8]   <= wdata;
                    7'h22: begin
                        uart_tx_r      <= wdata;
                        uart_tx_strobe <= 1'b1;
                    end
                    7'h30: begin
                        smp_arm_r <= wdata[0];
                        smp_rst_r <= wdata[1];
                    end
                    default: ;
                endcase
            end
        end
    end
endmodule
