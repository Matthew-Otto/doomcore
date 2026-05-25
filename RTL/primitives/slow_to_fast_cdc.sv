module slow_to_fast_cdc (
  input  logic clk,

  input  logic data_in,
  output logic data_out
);

  logic [2:0] sync_reg;

  always_ff @(posedge clk) begin
    sync_reg <= {sync_reg[1:0], data_in};
  end

  assign data_out = sync_reg[1] && ~sync_reg[2];

endmodule : slow_to_fast_cdc
