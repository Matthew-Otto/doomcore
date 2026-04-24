// Calculates PC and fetches instructions from i_mem

`include "defines.svh"

module fetch (
    input  logic        clk,
    input  logic        rst,
    input  logic        fetch_stall,
    
    input  logic        is_br_type,
    input  br_type_t    br_type,
    input  logic        take_branch,
    input  logic [31:0] rs1_data,
    input  logic [31:0] imm_b,
    input  logic [31:0] imm_i,
    input  logic [31:0] imm_j,

    output logic [31:0] i_addr,
    output logic [31:0] PC_f, // fetch stage PC
    output logic [31:0] PC_e, // execute stage PC
    output logic        flush
);

    logic [31:0] next_PC;
    logic        branch;
    logic [31:0] PC_addend1, PC_addend2;

    always_ff @(posedge clk, posedge rst) begin
        if (rst)               PC_f <= 32'h80000000;
        else if (~fetch_stall) PC_f <= next_PC;
    end        
    always_ff @(posedge clk, posedge rst) begin
        if (rst)               PC_e <= '0;
        else if (~fetch_stall) PC_e <= PC_f;
    end
    always_ff @(posedge clk, posedge rst) begin
        if (rst)               flush <= 1'b1;
        else if (~fetch_stall) flush <= branch;
    end

    always_comb begin
        casez ({flush,is_br_type,br_type,take_branch})
            5'b01001 : begin // Branch (taken)
                branch = 1'b1;
                PC_addend1 = PC_e;
                PC_addend2 = imm_b;
            end
            5'b0111? : begin // Jump
                branch = 1'b1;
                PC_addend1 = PC_e;
                PC_addend2 = imm_j;
            end
            5'b0101? : begin // Jump reg
                branch = 1'b1;
                PC_addend1 = rs1_data;
                PC_addend2 = imm_i;
            end
            default : begin
                branch = 1'b0;
                PC_addend1 = PC_f;
                PC_addend2 = 4;
            end
        endcase
    end

    assign next_PC = PC_addend1 + PC_addend2;

    assign i_addr = fetch_stall ? PC_e : PC_f;

endmodule : fetch
