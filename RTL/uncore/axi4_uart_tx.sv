module axi4_uart_tx #(
    parameter int ID_WIDTH  = 1,
    parameter int CLK_FREQ  = 50_000_000, // System clock frequency in Hz
    parameter int BAUD_RATE = 115200      // Target UART baud rate
)(
    input  logic clk,
    input  logic rst,

    AXI_BUS.Slave axi_s,
    output logic uart_tx
);

    // Read Channel Tie-Offs (Write-Only Module)
    assign axi_s.ar_ready = 1'b0;
    assign axi_s.r_valid  = 1'b0;
    assign axi_s.r_data   = '0;
    assign axi_s.r_resp   = 2'b00;
    assign axi_s.r_last   = 1'b0;
    assign axi_s.r_id     = '0;

    enum {
        IDLE,
        WAIT_W,
        RESP
    } state;

    logic [ID_WIDTH-1:0] awid_q;
    
    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;


    // AXI Write Slave FSM
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_start  <= 1'b0;
            tx_data   <= '0;
            awid_q    <= '0;
        end else begin
            tx_start <= 1'b0; // Default to single-cycle pulse
            
            case (state)
                IDLE: begin
                    // Accept Address Write when UART is free
                    if (axi_s.aw_valid && !tx_busy) begin
                        awid_q <= axi_s.aw_id;
                        
                        // If Data is also valid, consume both and transmit
                        if (axi_s.w_valid) begin
                            tx_data   <= axi_s.w_data[7:0];
                            tx_start  <= 1'b1;
                            state <= RESP;
                        end else begin
                            state <= WAIT_W;
                        end
                    end
                end
                
                WAIT_W: begin
                    // Wait for delayed Write Data
                    if (axi_s.w_valid) begin
                        tx_data   <= axi_s.w_data[7:0];
                        tx_start  <= 1'b1;
                        state <= RESP;
                    end
                end
                
                RESP: begin
                    // Wait for Master to accept the B-Channel response
                    if (axi_s.b_valid && axi_s.b_ready) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Combinational AXI Ready/Valid signaling based on FSM state
    assign axi_s.aw_ready = (state == IDLE) && !tx_busy;
    assign axi_s.w_ready  = ((state == IDLE) && axi_s.aw_valid && !tx_busy) || (state == WAIT_W);
    
    assign axi_s.b_valid  = (state == RESP);
    assign axi_s.b_resp   = 2'b00; // OKAY response
    assign axi_s.b_id     = awid_q;

    //UART Transmitter
    localparam int unsigned BAUD_DIV = CLK_FREQ / BAUD_RATE;
    
    logic [$clog2(BAUD_DIV):0] baud_cnt;
    logic [3:0]                bit_cnt;
    logic [9:0]                shift_reg; // {Stop(1), Data[7:0], Start(0)}

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_busy   <= 1'b0;
            uart_tx      <= 1'b1; // Line idles high
            baud_cnt  <= '0;
            bit_cnt   <= '0;
            shift_reg <= '1;
        end else begin
            if (tx_start) begin
                tx_busy   <= 1'b1;
                shift_reg <= {1'b1, tx_data, 1'b0};
                baud_cnt  <= BAUD_DIV - 1;
                bit_cnt   <= 4'd10;
            end else if (tx_busy) begin
                if (baud_cnt == 0) begin
                    baud_cnt <= BAUD_DIV - 1;
                    uart_tx     <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]}; // Shift right
                    bit_cnt  <= bit_cnt - 4'd1;
                    
                    if (bit_cnt == 4'd1) begin
                        tx_busy <= 1'b0; // Last bit finished
                    end
                end else begin
                    baud_cnt <= baud_cnt - 1;
                end
            end
        end
    end

endmodule : axi4_uart_tx
