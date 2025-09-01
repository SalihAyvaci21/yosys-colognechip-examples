`timescale 1ns / 1ps
//DEMSAY ELEKTRONİK - ARGE 
//Salih Tekin Ayvaci - FIELD APPLICATION ENGINEER 
//12.06.2025

module debounce_ip_core #(
   parameter CLK_FREQ_HZ = 10_000_000 , // 10 MHz
      // Sistem saat frekansı (Hz)
    //parameter STABLE_TIME_MS = 2,             // Kararlı hale gelme süresi (ms)
    parameter SHIFT_LEN = 3,                  // Shift register uzunluğu (n bit)
    parameter IS_PULLUP = 0                   // 1: pull-up buton, 0: pull-down buton
)(
    input  wire clk,                          // Sistem saati
                              
    input  wire push_button,                  // Ham buton girişi

    output reg  out_valid,                    // Çıkış geçerlilik sinyali
    output reg  debounced_button              // Debounced buton çıkışı
    
); 

    // Shift register tanımı
    reg [SHIFT_LEN-1:0] shift_reg = {SHIFT_LEN{IS_PULLUP}}; 

    // XOR kontrol sinyali (kararlılık kontrolü)
    wire xor_out = ^(shift_reg ^ {SHIFT_LEN{shift_reg[0]}}); // Tüm bitler aynıysa xor_out = 0

    // Kararlılık sayaç limiti
    localparam integer MAX_COUNT = (CLK_FREQ_HZ / 1000);
    // Debounce süresi = 0.5 ms
// MAX_COUNT = CLK_FREQ_HZ * 0.0005 = CLK_FREQ_HZ / 2000

// Örnek değerler:
// 10 MHz  ? MAX_COUNT = 10_000_000 / 2000  = 5_000
// 20 MHz  ? MAX_COUNT = 20_000_000 / 2000  = 10_000
// 50 MHz  ? MAX_COUNT = 50_000_000 / 2000  = 25_000
// 100 MHz ? MAX_COUNT = 100_000_000 / 2000 = 50_000
// 125 MHz ? MAX_COUNT = 125_000_000 / 2000 = 62_500
// 200 MHz ? MAX_COUNT = 200_000_000 / 2000 = 100_000

// Hedef debounce süresi değiştirilecekse (örneğin 1ms), bölücü değeri de değişmelidir:
// 1 ms için ? CLK_FREQ_HZ / 1000
// 2 ms için ? CLK_FREQ_HZ / 500

    reg [17:0] counter = 0;

    // Senkronizasyon için 2FF zinciri
    reg sync_0 = IS_PULLUP;
    reg sync_1 = IS_PULLUP;
    reg init_done_ip = 0 ; 

    always @(posedge clk) begin
        if (!init_done_ip) begin
            sync_0 <= IS_PULLUP;
            sync_1 <= IS_PULLUP;
            shift_reg <= {SHIFT_LEN{IS_PULLUP}};
            debounced_button <= IS_PULLUP;
            counter <= 0;
            out_valid <= 0;
            init_done_ip <= 1; 
            
        end else begin
            // Senkronizasyon
            sync_0 <= push_button;
            sync_1 <= sync_0;

            // Shift register güncelleme
            shift_reg <= {shift_reg[SHIFT_LEN-2:0], sync_1};

            // XOR sonucu kararlıysa sayaç artar
            if (xor_out == 1'b0) begin
                if (counter < MAX_COUNT) begin
                    counter <= counter + 1;
                    out_valid <= 0;
                end else if (debounced_button != shift_reg[0]) begin
                    debounced_button <= shift_reg[0];
                    out_valid <= 1;
                end else begin
                    out_valid <= 0;
                end
            end else begin
                counter <= 0;
                out_valid <= 0;
            end
        end
    end

endmodule
