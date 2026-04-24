// load/store unit

// Loads take one cycle
// LS unit drives address to data mem d_addr,
// The requested data appears on d_wr_data in the next cycle.
// The data is written to the reg file on the next cycle.
// Data hazard calculation occurs in control.sv.

`include "defines.svh"

module LSU (
    input  logic        clk,
    input  logic        rst,
    input  logic        st_en,
    input  logic        ld_en,

    input  logic [4:0]  rd,
    input  logic [31:0] addr,
    input  logic        is_load_op,
    input  logic        is_store_op,
    input  load_op_t    load_op,
    input  store_op_t   store_op,

    input  logic [31:0] write_data,

    output logic        ld_valid,
    output logic [4:0]  ld_rd,
    output logic [31:0] ld_rd_data,

    output logic [31:0] d_addr,
    output logic [3:0]  d_we,
    output logic [31:0] d_wr_data,
    input  logic [31:0] d_rd_data
);

    assign d_addr = addr;
    assign d_wr_data = write_data;

    // Store
    logic we;
    logic [3:0] we_mask;

    assign we = st_en & is_store_op;
    assign d_we = {4{we}} & we_mask;

    always_comb begin
        case (store_op)
            i_SB   : we_mask = 4'b0001;
            i_SH   : we_mask = 4'b0011;
            i_SW   : we_mask = 4'b1111;
            default: we_mask = 4'b1111;
        endcase
    end

    // Load
    load_op_t load_op_v;

    always_ff @(posedge clk) begin
        if (rst)  ld_valid <= 1'b0;
        else      ld_valid <= ld_en & is_load_op;
    end
    always_ff @(posedge clk) begin
        ld_rd <= rd;
        load_op_v <= load_op;
    end

    always_comb begin
        case (load_op_v)
            i_LB   : ld_rd_data = {{24{d_rd_data[7]}},d_rd_data[7:0]};
            i_LH   : ld_rd_data = {{16{d_rd_data[15]}},d_rd_data[15:0]};
            i_LW   : ld_rd_data = d_rd_data;
            i_LBU  : ld_rd_data = {24'b0,d_rd_data[7:0]};
            i_LHU  : ld_rd_data = {16'b0,d_rd_data[15:0]};
            default: ld_rd_data = d_rd_data;
        endcase
    end

endmodule : LSU
