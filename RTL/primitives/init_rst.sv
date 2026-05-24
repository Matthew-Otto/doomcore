// Holds a reset signal for the first few cycles after initialization and PLL lock

module init_rst #(
    parameter int DELAY = 16
) (
    input  logic clk,
    input  logic pll_lock,
    output logic rst_out
);

    (* async_reg = "true" *) logic [1:0] sync_reg = 2'b11; 

    always_ff @(posedge clk) begin
        sync_reg <= {sync_reg[0], ~pll_lock};
    end

    logic synced_unlock;
    assign synced_unlock = sync_reg[1];


    logic [DELAY-1:0] shift_reg = '1;

    always_ff @(posedge clk) begin
        if (synced_unlock) begin
            shift_reg <= '1;
        end else begin
            shift_reg <= {shift_reg[DELAY-2:0], 1'b0};
        end
    end

    assign rst_out = shift_reg[DELAY-1];

endmodule : init_rst
