// Simple dual-port BRAM with write bypassing
// With byte-enable write mask

module dual_port_bram_be #(
    ADDR_WIDTH=8,
    DATA_WIDTH=32
)(
    input  logic                      clk,
    input  logic [(DATA_WIDTH/8)-1:0] wr_en,
    input  logic [ADDR_WIDTH-1:0]     write_addr,
    input  logic [DATA_WIDTH-1:0]     write_data,
    input  logic [ADDR_WIDTH-1:0]     read_addr,
    output logic [DATA_WIDTH-1:0]     read_data
);

    localparam MEM_DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];

    always_ff @(posedge clk) begin
        for (int i = 0; i < (DATA_WIDTH/8); i = i + 1) begin
            if (wr_en[i])
                mem[write_addr][i*8+:8] <= write_data[i*8+:8];
            
            read_data[i*8+:8] <= (wr_en[i] && (read_addr == write_addr)) ? write_data[i*8+:8] : mem[read_addr][i*8+:8];
        end
    end

endmodule : dual_port_bram_be