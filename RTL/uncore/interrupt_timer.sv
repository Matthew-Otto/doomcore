module interrupt_timer #(
    parameter int CLK_FREQ = 50_000_000,
    parameter int TIMER_US = 1
) (
    input  logic clk,
    input  logic rst,
    output logic interrupt
);

    localparam int TIMER_CNT = (CLK_FREQ / 1000_000) * TIMER_US;

    logic [$clog2(TIMER_CNT)-1:0] cnt;

    always_ff @(posedge clk) begin
        if (rst || cnt == 0) cnt <= TIMER_CNT-1;
        else cnt <= cnt - 1;
    end

    assign interrupt = (cnt == 0);

endmodule : interrupt_timer
