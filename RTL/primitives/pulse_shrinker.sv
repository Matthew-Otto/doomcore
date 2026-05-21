// 2:1 slow to fast synchronous CDC pulse shrinker

module pulse_shrinker (
    input  logic clk_fast,
    input  logic pulse_in,
    output logic pulse_out
);

    logic pulse_in_q;

    always_ff @(posedge clk_fast) begin
        pulse_in_q <= pulse_in;
        
        // output on the rising edge
        pulse_out  <= pulse_in & ~pulse_in_q;
    end

endmodule : pulse_shrinker
