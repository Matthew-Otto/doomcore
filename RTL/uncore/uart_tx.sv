module uart_tx #(
    parameter int CLK_RATE=100000000,
    parameter int BAUD_RATE=115200
)(
    input  logic clk,
    input  logic reset,

    output logic tx,
    input  logic [7:0] data,
    output logic ready,
    input  logic valid
);

    localparam int CLKS_PER_BAUD = CLK_RATE / BAUD_RATE;
    localparam int CNT_WIDTH = $clog2(CLKS_PER_BAUD);

    enum {
        IDLE,
        SHIFT,
        WAIT
    } state, next_state;

    logic [9:0] shift_reg;
    logic [3:0] bit_cnt, next_bit_cnt;
    logic [CNT_WIDTH-1:0] clk_cnt, next_clk_cnt;


    always_ff @(posedge clk) begin
        if (reset) state <= IDLE;
        else       state <= next_state;

        bit_cnt <= next_bit_cnt;
        clk_cnt <= next_clk_cnt;
    end

    always_comb begin
        next_state = state;
        next_bit_cnt = bit_cnt;
        next_clk_cnt = clk_cnt;

        ready = 0;

        case (state)
            IDLE : begin
                ready = 1;
                next_clk_cnt = CLKS_PER_BAUD - 2;
                next_bit_cnt = 9;
                if (valid)
                    next_state = WAIT;
            end

            WAIT : begin
                next_clk_cnt = clk_cnt - 1;
                if (clk_cnt == 0)
                    next_state = SHIFT;
            end

            SHIFT : begin
                next_clk_cnt = CLKS_PER_BAUD - 2;
                next_bit_cnt = bit_cnt - 1;
                if (bit_cnt == 0)
                    next_state = IDLE;
                else
                    next_state = WAIT;
            end

            default : next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset)
            shift_reg <= '1;
        else if (valid && ready)
            shift_reg <= {1'b1, data, 1'b0};
        else if (state == SHIFT)
            shift_reg <= {1'b1, shift_reg[9:1]};
    end

    assign tx = shift_reg[0];
  
endmodule : uart_tx
