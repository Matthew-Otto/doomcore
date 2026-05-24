module fb_uart_debug #(
    parameter int CLK_FREQ = 25200000,
    parameter int BAUD_RATE = 115200
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       trigger,      // Start dump on rising edge

    // Framebuffer interface
    output logic [15:0] fb_read_addr,
    input  logic [7:0]  fb_read_data,

    output logic       uart_tx
);

    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam int TOTAL_PIXELS = 320 * 200;

    enum {
        IDLE,
        READ_PIXEL,
        SEND_START,
        SEND_BITS,
        SEND_STOP,
        NEXT_PIXEL
    } state;

    logic [15:0] addr_cnt;
    logic [3:0]  bit_cnt;
    logic [15:0] clk_cnt;
    logic [7:0]  tx_data;

    assign fb_read_addr = addr_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            addr_cnt <= 0;
            clk_cnt <= 0;
            uart_tx <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    uart_tx <= 1'b1;
                    if (trigger) begin
                        addr_cnt <= 0;
                        state <= READ_PIXEL;
                    end
                end

                READ_PIXEL: begin
                    // Wait 1 cycle for BRAM latency
                    tx_data <= fb_read_data;
                    clk_cnt <= 0;
                    state <= SEND_START;
                end

                SEND_START: begin
                    uart_tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        state <= SEND_BITS;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                SEND_BITS: begin
                    uart_tx <= tx_data[bit_cnt];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_cnt == 7) begin
                            state <= SEND_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                SEND_STOP: begin
                    uart_tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state <= NEXT_PIXEL;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                NEXT_PIXEL: begin
                    if (addr_cnt == TOTAL_PIXELS - 1) begin
                        state <= IDLE;
                    end else begin
                        addr_cnt <= addr_cnt + 1;
                        state <= READ_PIXEL;
                    end
                end
            endcase
        end
    end

endmodule
