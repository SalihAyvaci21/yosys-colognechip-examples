## Counter_led

- LED’leri ileri–geri yakıp söndürmek (chase effect)
- Butona basıldığında hızını değiştirmek (1s → 0.5s → 0.25s → tekrar 1s…)

---

#  Counter_led Algoritması

## 📌 Adım Adım Algoritma

1. **Başlangıç (Reset):**
    
    - Tüm sayaçlar sıfırlanır.
    - LED0 yanar, diğerleri sönük olur.
    - Yön ileri (soldan sağa).
    - Hız modu 1 saniye seçilir.
    
2. **Butona Basıldığında:**
    
    - Buton sinyali **debounce modülü** ile temizlenir (gürültü yok).
    - Her basışta hız modu değişir:
    - 1s → 0.5s → 0.25s → tekrar 1s.
    
3. **Clock Divider:**
    
    - Seçilen moda göre sayaç çalışır.
    - Sayaç dolunca bir **pulse** üretilir.
    
4. **LED Chase Hareketi:**
    
    - Pulse geldiğinde aktif LED değiştirilir.
    - LED ileri yönde yanıyorsa sağa doğru kayar.
    - En sağa ulaştığında yön tersine döner.
    - En sola ulaştığında tekrar ileri yön olur.
        


---

# **Counter LED**

**Görev Tanımı:**  
FPGA üzerinde ileri–geri kayan LED efektini gerçekleştirmek.  
Butona basıldığında LED’in kayma hızı değişir: **1 saniye → 0.5 saniye → 0.25 saniye → tekrar 1 saniye.**

---

## 🎯 **Amaç**

- Sayaç kullanarak clock bölme mantığını öğrenmek
- LED dizisinde ileri–geri hareket efektini uygulamak
- Butonla **hız değiştirme** işlevini uygulamak
- Debounce IP core ile buton gürültüsünü temizlemek
- FSM (finite state machine) mantığını kavramak

---

## 📂 Proje Yapısı

counter_led/  
│── log/ # Log kayıtları  
│── net/ # Sentez sonucu netlist dosyaları  
│── sim/ # Testbench dosyaları  
│── src/ # Kaynak kodlar (.v) + .ccf constraints dosyaları  
│── Makefile # Build ayarları  
│── run.bat # Çalıştırma scripti

---

## 💡 Örnek Kod: Counter_led


`timescale 1ns / 1ps
// DEMSAY ELEKTRONİK - ARGE
// Salih Tekin Ayvaci - FIELD APPLICATION ENGINEER
// 12.06.2025

module Counter_led (
    input  wire clk,           // 10 MHz sistem clock girişi
    input  wire rst,           // reset (aktif düşük) sinyali
    input  wire push_button,   // hız değiştirmek için buton girişi
    output reg  [7:0] led_out  // 8-bit LED çıkışı (aktif düşük LED’ler)
);

    // =======================
    // Debounce modülü bağlantısı
    // =======================
    wire debounced_button;     // debounce edilmiş (temizlenmiş) buton çıkışı
    wire out_valid;            // buton geçerli basış sinyali (1 pulse üretir)

    // Debounce modülü örnekleniyor
    debounce_ip_core #(
        .CLK_FREQ_HZ(10_000_000), // Sistem clock frekansı = 10 MHz
        .SHIFT_LEN(3),            // 3 bitlik shift register (debounce filtresi)
        .IS_PULLUP(0)             // Buton pull-down bağlı
    ) debounce_inst (
        .clk(clk),                // Sistem saatini bağla
        .push_button(push_button),// Ham buton sinyali
        .out_valid(out_valid),    // Çıkış pulse’u (tek clock genişlikli)
        .debounced_button(debounced_button) // Kararlı buton değeri
    );

    // =======================
    // Clock divider ayarları (farklı hızlar için)
    // =======================
    localparam integer COUNT_1S   = 1_000_000 - 1; // 1 saniyelik sayaç (10 MHz → 10M cycle)
    localparam integer COUNT_05S  = 500_000  - 1; // 0.5 saniyelik sayaç
    localparam integer COUNT_025S = 750_000  - 1; // 0.25 saniyelik sayaç

    reg [23:0] counter = 0;    // clock bölücü sayacı
    reg one_sec_pulse = 0;     // clock bölücünün çıkışı (belirtilen sürede 1 pulse üretir)

    // =======================
    // Hız modu seçimi
    // =======================
    reg [1:0] speed_mode = 0;  // 0=1s, 1=0.5s, 2=0.25s

    // Butona basıldıkça hız modu değiştirilir
    always @(posedge clk or negedge rst) begin
        if (!rst)                        // reset aktif → sıfırla
            speed_mode <= 0;             // başlangıçta 1 saniyelik mod
        else if (out_valid)              // butona basıldığında
            speed_mode <= (speed_mode == 2) ? 0 : speed_mode + 1; 
            // Eğer mod 2 (0.25s) ise tekrar 0’a (1s) döner
    end

    // Clock divider → seçilen moda göre sayacı çalıştırır
    always @(posedge clk or negedge rst) begin
        if (!rst) begin                  // reset aktif
            counter <= 0;
            one_sec_pulse <= 0;
        end else begin
            case (speed_mode)
                2'd0: if (counter == COUNT_1S) begin     // 1 saniye say
                          counter <= 0; 
                          one_sec_pulse <= 1;           // pulse üret
                      end else begin
                          counter <= counter + 1; 
                          one_sec_pulse <= 0;           // normalde 0
                      end
                2'd1: if (counter == COUNT_05S) begin    // 0.5 saniye say
                          counter <= 0; 
                          one_sec_pulse <= 1;
                      end else begin
                          counter <= counter + 1; 
                          one_sec_pulse <= 0;
                      end
                2'd2: if (counter == COUNT_025S) begin   // 0.25 saniye say
                          counter <= 0; 
                          one_sec_pulse <= 1;
                      end else begin
                          counter <= counter + 1; 
                          one_sec_pulse <= 0;
                      end
            endcase
        end
    end

    // =======================
    // LED chase (ileri-geri kayan ışık) kontrolü
    // =======================
    reg [2:0] led_index = 0;   // aktif LED indeksi (0–7)
    reg dir = 0;               // 0: ileri, 1: geri yön

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            led_out   <= 8'b1111_1110; // başlangıçta LED0 yanık (aktif düşük)
            led_index <= 0;            // ilk LED seçili
            dir       <= 0;            // yön ileri
        end else if (one_sec_pulse) begin // sadece bölücü pulse ürettiğinde değiştir
            led_out <= 8'b1111_1111;   // önce tüm LED’leri söndür
            led_out[led_index] <= 1'b0; // seçilen LED’i yak

            // LED ileri-geri hareket mantığı
            if (dir == 0) begin                 // ileri yönde
                if (led_index == 7) begin       // en sağa geldiyse
                    dir <= 1;                   // yönü ters çevir
                    led_index <= 6;             // bir önceki LED’e dön
                end else begin
                    led_index <= led_index + 1; // bir sonraki LED
                end
            end else begin                      // geri yönde
                if (led_index == 0) begin       // en sola geldiyse
                    dir <= 0;                   // yönü ileri yap
                    led_index <= 1;             // bir sonraki LED
                end else begin
                    led_index <= led_index - 1; // bir önceki LED
                end
            end
        end
    end

endmodule


![[Counter_led.v]]


---

##  Çalışma Mantığı

- **Debouncer:** Butondan gelen gürültüyü temizler, tek pulse üretir.
- **Clock Divider:** 10 MHz clock’tan 1s, 0.5s, 0.25s aralıklarında pulse üretir.
- **Speed Mode:** Buton basıldıkça hız modu değişir.
- **LED Chase:** Pulse geldikçe aktif LED değiştirilir, sağdan sola – soldan sağa kayar.
    

---

## 📌 Constraints Dosyası (`.ccf`)



 **Clock input (e.g., 10 MHz from onboard oscillator)**
Net "clk"         Loc = "IO_SB_A8";      # Clock pin

 **Push-button input (SW3)**
Net "push_button" Loc = "IO_EB_B0";      # Active-low mechanical button

 **8-bit active-low LED outputs**
Net "led_out[0]"  Loc = "IO_EB_B1";      # D1
Net "led_out[1]"  Loc = "IO_EB_B2";      # D2
Net "led_out[2]"  Loc = "IO_EB_B3";      # D3
Net "led_out[3]"  Loc = "IO_EB_B4";      # D4
Net "led_out[4]"  Loc = "IO_EB_B5";      # D5
Net "led_out[5]"  Loc = "IO_EB_B6";      # D6
Net "led_out[6]"  Loc = "IO_EB_B7";      # D7
Net "led_out[7]"  Loc = "IO_EB_B8";      # D8


