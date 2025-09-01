`timescale 1ns / 1ps
// DEMSAY ELEKTRONİK - ARGE
// Salih Tekin Ayvaci - FIELD APPLICATION ENGINEER
// 12.06.2025

module Blink8_1(
    input  wire clk,          // 10 MHz sistem clock
    input  wire rst,          // reset (aktif düşük)
    input  wire push_button,  // buton girişi
    output reg  [7:0] led     // aktif-low LED çıkışları
);

    // ======================
    // Debounce Modülü
    // ======================
    wire debounced_button;
    wire out_valid;

    debounce_ip_core #(
        .CLK_FREQ_HZ(10_000_000), // 10 MHz sistem clock
        .SHIFT_LEN(3),            // 3 bit filtre
        .IS_PULLUP(0)             // pull-down buton
    ) debounce_inst (
        .clk(clk),
        .push_button(push_button),
        .out_valid(out_valid),          // butona basıldığında pulse
        .debounced_button(debounced_button) // kararlı buton değeri
    );

    // ======================
    // PLL (10 MHz → 100 MHz)
    // ======================
    reg [26:0] counter;

    wire clk270, clk180, clk90, clk0, usr_ref_out;
    wire usr_pll_lock_stdy, usr_pll_lock;

    CC_PLL #(
        .REF_CLK("10.0"),
        .OUT_CLK("100.0"),
        .PERF_MD("ECONOMY"),
        .LOW_JITTER(1),
        .CI_FILTER_CONST(2),
        .CP_FILTER_CONST(4)
    ) pll_inst (
        .CLK_REF(clk), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
        .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
        .CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clk0), .CLK_REF_OUT(usr_ref_out)
    );

    // ======================
    // Sayaç
    // ======================
    always @(posedge clk0) begin
        if (!rst)
            counter <= 0;
        else
            counter <= counter + 1'b1;
    end

    // ======================
    // LED Kontrol
    // ======================
    always @(*) begin
        if (!rst) begin
            led = 8'b1111_1111;  // reset → hepsi sönük
        end else if (counter[26] == 1'b1) begin
            led = 8'b0000_0000;  // normal durumda → tüm LED yanık
        end else begin
            led = 8'b1111_1110;  // normal durumda → sadece LED0 yanık
        end
    end

endmodule
