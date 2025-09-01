# **Chase&Toggle**

**Görev Tanımı:**  
FPGA üzerinde LED dizisini kontrol etmek. Default modda LED’ler ileri-geri efektle yanıp söner (**Chase Mode**). Push-button ile **Toggle Mode**’a geçildiğinde ise tüm LED’ler açılır/kapanır.

---

## 🎯 **Amaç**

- Sayaç kullanmak, bölme mantığını öğrenmek
- LED dizisinde efekt uygulamak (chase)
- Butonla birden fazla kontrol değişimini öğrenmek (toggle)
- Debounce IP core ile buton gürültüsünü temizlemek
- Tek pulse üretip kontrol işlevi sağlamak

---
## Algoritma Adımları

1. **Debounce İp Core**
    
    - Butonun stabil çalışması için bir debounce ip core yazıldı.
        
2. **Tanımlamalar**
    
    - Toggle_mode tanımlaması butona basılıp basılmadığını anlayan parametre
        
    - Toggle tanımlaması butonun bir öncekinden farklı değişken atamasını sağlayan parametre.
        
    - Counter sayaç tanımlaması ilk 4 led ve 4 led arasındaki süreyi belirler.
.
            
1. **Buton Takip**
    
    - Case yapısı sayesinde buton en son toggle değerini kaçta bıraktıysa o çalışmaktadır bu sayede bir butona basınca ledler yanıp bir butona basıldığında sönebilmektedir.
        
    - Sayaç belli bir değere geldiğinde LED deseni değişir.
        
    - Bu sayede LED’ler sırayla yanıp söner → sağdan sola ya da soldan sağa kayan ışık efekti oluşur.

--- 
## 📂 Proje Yapısı

chase_toggle/  
│── log/ # Log kayıtları  
│── net/ # Sentez sonucu netlist dosyaları  
│── sim/ # Testbench dosyaları (Icarus Verilog / iverilog için)  
│── src/ # Kaynak kodlar (.v / .vhd) + .ccf constraints dosyaları  
│── Makefile # Build ayarları  
│── run.bat # Çalıştırma scripti

**Not:**

- `Makefile` içindeki `TOP` değişkeni **top modul** ismiyle aynı olmalıdır.
- `.ccf` dosyası da top modul ismiyle birebir aynı olmalıdır.

---

## ⚙️ Makefile İçeriği

include ../config.mk

TOP = Chase&Toggle


PRFLAGS += -ccf src/$(TOP).ccf -cCP

---

## ⚡ Run.bat İçeriği

:: toolchain
set YOSYS=../../bin/yosys/yosys.exe
set PR=../../bin/p_r/p_r.exe
set OFL=../../bin/openFPGALoader/openFPGALoader.exe

:: project name and sources
set TOP=Chase&Toggle
set SRC=src/Chase&Toggle.v src/debounce_ip_core.v
set VHDL_SRC=
set LOG=0


Eğer proje birden fazla dosyadan oluşuyorsa:

set TOP=Chase&Toggle
set SRC=src/Chase&Toggle.v src/debounce_ip_core.v

---

## 💡 Örnek Kod: Chase&Toggle

`timescale 1ns / 1ps
// DEMSAY ELEKTRONİK - ARGE
// Salih Tekin Ayvaci - FIELD APPLICATION ENGINEER
// 12.06.2025

module Chase&Toggle(
    input  wire clk,           // 10 MHz sistem clock girişi
    input  wire rst,           // reset (aktif düşük) sinyali
    input  wire push_button,   // buton girişi (LED aç/kapa kontrolü)
    output reg  [7:0] led_out  // 8-bit LED çıkışı (aktif düşük LED'ler)
);

    // =======================
    // Debounce modülü bağlantısı
    // =======================
    wire debounced_button;     // butonun temizlenmiş hali (sıçramalar giderilir)
    wire out_valid;            // butona tek basıştan çıkan 1 clock genişlikli pulse

    debounce_ip_core #(
        .CLK_FREQ_HZ(10_000_000), // Sistem clock frekansı = 10 MHz
        .SHIFT_LEN(3),            // debounce için kullanılan shift register uzunluğu
        .IS_PULLUP(0)             // buton pull-down bağlı olduğunu belirtiyor
    ) debounce_inst (
        .clk(clk),                // clock girişi
        .push_button(push_button),// ham buton girişi
        .out_valid(out_valid),    // geçerli buton pulse çıkışı
        .debounced_button(debounced_button) // kararlı buton çıkışı
    );

    reg [26:0] counter;        // uzun sayaç (0.5 saniye vb. zaman üretmek için kullanılabilir)
    reg toggle;                // LED desenini değiştirmek için kullanılan bit
    reg toggle_mode;           // 0=normal mod, 1=toggle mod (buton ile değişir)

    // ======================
    // Sayaç
    // ======================
    always @(posedge clk or negedge rst) begin
        if (!rst)               // reset aktifken sayaç sıfırlanır
            counter <= 0;
        else
            counter <= counter + 1'b1; // her clockta sayaç artar
    end

    // =======================
    // Toggle Mode (buton ile)
    // =======================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            toggle_mode <= 0;          // reset → normal mod
        end else if (out_valid) begin
            toggle_mode <= ~toggle_mode; // butona basıldığında mod değiştir
        end
    end


    // =======================
    // LED çıkış kontrolü (tek block!)
    // =======================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            led_out <= 8'b1111_1111; // reset → tüm LED'ler kapalı
        end else if (toggle_mode) begin
            // Toggle mod aktif olduğunda: LED’ler toggle’a göre değişir
case (toggle)
    1'b0: begin 
        if (toggle == 1'b0) begin
            led_out <= 8'b0000_0000; // tüm LED’ler yanar
        end 
        if (out_valid == 1'b1) begin
            toggle  <= 1'b1;        // butona tekrar basılırsa toggle 1 yapılır
        end
    end
    1'b1: begin 
        if (toggle == 1'b1) begin
            led_out <= 8'b1111_1111; // tüm LED’ler kapanır
        end 
        if (out_valid == 1'b1) begin
            toggle  <= 1'b0;        // butona tekrar basılırsa toggle 0 yapılır
        end
    end
endcase

        end else begin
            // Normal modda: LED0 ↔ LED7 arasında yanıp sönüyor
            if (counter[26] == 1'b1)
                led_out <= 8'b1111_0000; // LED0..3 kapalı, LED4..7 açık
            else
                led_out <= 8'b0000_1111; // LED0..3 açık, LED4..7 kapalı
        end
    end

endmodule


![[Chase&Toggle.v]]

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


![[Chase&Toggle.ccf]] 
