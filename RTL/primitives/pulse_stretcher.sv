// glitchless fast to slow synchronous CDC pulse stretcher

module pulse_stretcher #(
    parameter FACTOR = 2 
) (
    input  logic clk_fast,
    input  logic pulse_in,
    output logic pulse_out
);

    logic [FACTOR-2:0] shift_reg;

    always_ff @(posedge clk_fast) begin
        shift_reg <= (shift_reg << 1) | pulse_in;
        pulse_out <= pulse_in | (|shift_reg); 
    end

endmodule : pulse_stretcher
