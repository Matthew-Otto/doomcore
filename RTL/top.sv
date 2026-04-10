// Top module for doomcore project

module top (
    input  logic       clk,
    //input  logic       clk0,
    //input  logic       clk1,
    //input  logic       clk2,
    input  logic       btn1,
    input  logic       btn2,

    //input  logic       uart_rx,
    //output logic       uart_tx,

    // HDMI
    output logic tmds_clk_p, // pixel clock
    output logic tmds_d0_p,  // blue channel
    output logic tmds_d1_p,  // green channel
    output logic tmds_d2_p,  // red channel

    // Embedded SDRAM port names
    output logic        O_sdram_clk,
    output logic        O_sdram_cke,
    output logic        O_sdram_cs_n,     // chip select
    output logic        O_sdram_cas_n,    // columns address select
    output logic        O_sdram_ras_n,    // row address select
    output logic        O_sdram_wen_n,    // write enable
    inout  logic [31:0] IO_sdram_dq,      // 32 bit bidirectional data bus
    output logic [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
    output logic [1:0]  O_sdram_ba,       // two banks
    output logic [3:0]  O_sdram_dqm,      // 32/4
    
    output logic [5:0] led
);

    ////////////////////////////////////////////////////////////////////////
    //// clocks ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    logic sys_clk;   // main system clock
    logic sdram_clk; // sdram clock
    logic p_clk;     // HDMI pixel clock
    logic s_clk;     // HDMI serializer clock (10 bit / p_clk) (DDR)

    //// System Clock
    rPLL #(
        .FCLKIN("27.0"),
        .IDIV_SEL(4),   // -> PFD = 5.4 MHz (range: 3-500 MHz)
        .FBDIV_SEL(55), // -> CLKOUT = 302.4 MHz (range: 3.90625-625 MHz)
        .ODIV_SEL(2)    // -> VCO = 604.8 MHz (range: 500-1250 MHz)
    ) sysclk_pll_i (
        .CLKOUTP(),
        .CLKOUTD(),
        .CLKOUTD3(),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKFB(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0),
        .CLKIN(clk),      // 27.0 MHz
        .CLKOUT(sys_clk), // 302.4 MHz
        .LOCK()
    );

    //// SDRAM clock generator
    CLKDIV #(
        .DIV_MODE("2")
    ) sdram_clk_div_i (
        .HCLKIN(sys_clk),
        .RESETN(~reset),
        .CALIB(1'b0),
        .CLKOUT(sdram_clk) // 151.2 MHz
    );

    //// Serial clock generator
    rPLL #(
        .FCLKIN("27.0"),
        .IDIV_SEL(2),   // -> PFD = 9.0 MHz (range: 3-500 MHz)
        .FBDIV_SEL(13), // -> CLKOUT = 126.0 MHz (range: 3.90625-625 MHz)
        .ODIV_SEL(4)    // -> VCO = 504.0 MHz (range: 500-1250 MHz)
    ) sclk_pll_i (
        .CLKOUTP(),
        .CLKOUTD(),
        .CLKOUTD3(),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKFB(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0),
        .CLKIN(clk),    // 27.0 MHz
        .CLKOUT(s_clk), // 126.0 MHz
        .LOCK()
    );

    //// Pixel clock generator
    CLKDIV #(
        .DIV_MODE("5")
    ) pclk_div_i (
        .HCLKIN(s_clk),
        .RESETN(~reset),
        .CALIB(1'b0),
        .CLKOUT(p_clk) // 25.2 MHz
    );


    ////////////////////////////////////////////////////////////////////////
    //// user IO ///////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    logic btn1_db;

    debounce #(
        .CLK_FREQ(100000000),
        .PULSE(1)
    ) db_1 (
        .clk(sys_clk),
        .db_in(btn1),
        .db_out(btn1_db)
    );

    ////////////////////////////////////////////////////////////////////////
    //// reset /////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    logic reset;
    logic reset_i;

    init_rst init_rst_i (
        .clk(sys_clk),
        .reset(reset_i)
    );

    assign reset = reset_i | btn1_db;


    ////////////////////////////////////////////////////////////////////////
    //// display ///////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    display_driver display_driver_i (
        .p_clk,
        .s_clk,
        .reset,
        .serial_pclk(tmds_clk_p),
        .serial_blue(tmds_d0_p),
        .serial_green(tmds_d1_p),
        .serial_red(tmds_d2_p)
    );



// ---------------------------------------------------------
    // DUMMY LOGIC FOR COMPILATION TESTING
    // If you don't have your controller written yet, you must 
    // assign these to something so Yosys doesn't delete them.
    // ---------------------------------------------------------
    
    assign O_sdram_clk   = sdram_clk;
    assign O_sdram_cs_n  = 1'b0;
    assign O_sdram_ras_n = 1'b1;
    assign O_sdram_cas_n = 1'b1;
    assign O_sdram_wen_n = 1'b1;
    assign O_sdram_ba    = '0;
    assign O_sdram_addr  = '0;
    assign O_sdram_dqm   = 4'b0000;

endmodule : top
