module control (
    input  logic clk,
    input  logic rst,

    input  logic interrupt,
    input  logic wfi,

    input  logic branch_EX,
    input  logic ready_LS,

    input  logic valid_DE,
    input  logic valid_EX,
    input  logic valid_LS,

    output logic flush_DE,
    output logic flush_EX,
    output logic flush_LS,

    output logic stall_DE,
    output logic stall_EX,
    output logic stall_LS,
    output logic stall_FE,

    // Source Bypass/Hazard
    input  logic       is_writeback_DE,
    input  logic       is_imm_DE,
    input  logic [4:0] rd_addr_DE,
    input  logic [4:0] rs1_addr_DE,
    input  logic [4:0] rs2_addr_DE,

    input  logic       is_load_op_EX,
    input  logic [4:0] rd_addr_EX,

    input  logic       is_load_op_LS,
    input  logic       is_store_op_LS,
    input  logic [4:0] rd_addr_LS,
    input  logic [4:0] ld_rd_addr_LS,
    input  logic       ld_inflight_LS,
    input  logic       ld_valid_LS
);

    // Stall when waiting for interrupts
    logic wfi_stall;

    always_ff @(posedge clk) begin
        if (rst || interrupt) wfi_stall <= 1'b0;
        else if (wfi && valid_EX && ~stall_EX) wfi_stall <= 1'b1;
    end


    logic rd_match_EX;
    logic rs1_match_EX;
    logic rs2_match_EX;
    logic source_hazard_EX;

    logic rd_match_LS_dispatch;
    logic rs1_match_LS_dispatch;
    logic rs2_match_LS_dispatch;
    logic source_hazard_LS_dispatch;
    logic rd_match_LS_inflight;
    logic rs1_match_LS_inflight;
    logic rs2_match_LS_inflight;
    logic source_hazard_LS_inflight;
    logic source_hazard_LS;

    logic LSU_busy;

    // Stall if DE depends on destination of Load in EX
    // Other dependencies in EX will be forwarded automatically in regfile
    assign rd_match_EX = (rd_addr_DE == rd_addr_EX) && is_writeback_DE;
    assign rs1_match_EX = (rs1_addr_DE == rd_addr_EX);
    assign rs2_match_EX = (rs2_addr_DE == rd_addr_EX) && ~is_imm_DE;
    assign source_hazard_EX = valid_EX && is_load_op_EX && (rd_match_EX || rs1_match_EX || rs2_match_EX);

    // Stall if DE depends on destination of Load in LS and the result is not ready
    assign rd_match_LS_dispatch = (rd_addr_DE == rd_addr_LS) && is_writeback_DE;
    assign rs1_match_LS_dispatch = (rs1_addr_DE == rd_addr_LS);
    assign rs2_match_LS_dispatch = (rs2_addr_DE == rd_addr_LS) && ~is_imm_DE;
    assign source_hazard_LS_dispatch = valid_LS && is_load_op_LS && (rd_match_LS_dispatch || rs1_match_LS_dispatch || rs2_match_LS_dispatch);

    assign rd_match_LS_inflight = (rd_addr_DE == ld_rd_addr_LS) && is_writeback_DE;
    assign rs1_match_LS_inflight = (rs1_addr_DE == ld_rd_addr_LS);
    assign rs2_match_LS_inflight = (rs2_addr_DE == ld_rd_addr_LS) && ~is_imm_DE;
    assign source_hazard_LS_inflight = ld_inflight_LS && (rd_match_LS_inflight || rs1_match_LS_inflight || rs2_match_LS_inflight) && ~ld_valid_LS;

    assign source_hazard_LS = source_hazard_LS_dispatch || source_hazard_LS_inflight;
   
    // Stall LD/ST op in LS if the LSU unit is busy
    assign LSU_busy = valid_LS && (is_load_op_LS || is_store_op_LS) && ~ready_LS;

    // pipeline control
    assign stall_LS = LSU_busy;
    assign flush_LS = rst;

    assign stall_EX = stall_LS || wfi_stall;
    assign flush_EX = rst || branch_EX;
    
    assign stall_DE = stall_EX || source_hazard_EX || source_hazard_LS;
    assign flush_DE = rst || branch_EX;
    
    assign stall_FE = stall_DE;

endmodule : control
