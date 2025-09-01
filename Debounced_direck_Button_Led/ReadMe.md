# **Button → LED Toggle (Debounced)**

**Görev Tanımı:**  
FPGA üzerinde **debounce edilmiş buton sinyaliyle** LED kontrolü.  
Butona her basıldığında LED durumu **toggle (aç/kapa)** yapılır.  
Debounce IP Core sayesinde hızlı bas/çek hareketlerinde **gürültü ve sinyal kayması gözlenmez**.

---

## 🎯 **Amaç**

- Buton gürültüsünün (bounce) FPGA tarafında nasıl temizlendiğini göstermek
- `debounce_ip_core` kullanarak **tek, temiz pulse** üretmek
- Toggle mantığını uygulamak (her basışta LED’in durumu değişir)
- Aktif-low LED kontrolünü öğrenmek
    

---

## 📂 Proje Yapısı

button_led_toggle/  
│── log/ # Log kayıtları  
│── net/ # Sentez sonucu netlist dosyaları  
│── sim/ # Testbench dosyaları  
│── src/ # Kaynak kodlar (.v) + .ccf constraints  
│── Makefile # Build ayarları  
│── run.bat # Çalıştırma scripti

---

## 💡 Örnek Kod

`timescale 1ns / 1ps
// DEMSAY ELEKTRONİK - ARGE
// Salih Tekin Ayvaci - FIELD APPLICATION ENGINEER
// 12.06.2025

module ButtonLedToggle (
    input  wire clk,          // 10 MHz sistem clock
    input  wire rst_n,        // reset (aktif düşük)
    input  wire push_button,  // ham buton girişi
    output reg  led_out       // LED çıkışı (aktif-low)
);

    // ======================
    // Debouncer
    // ======================
    wire debounced_button;
    wire out_valid; // butona geçerli basış geldiğinde 1 clock pulse

    debounce_ip_core #(
        .CLK_FREQ_HZ(10_000_000),
        .SHIFT_LEN(3),
        .IS_PULLUP(0)             
    ) debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .push_button(push_button),
        .out_valid(out_valid),
        .debounced_button(debounced_button)
    );

    // ======================
    // LED Toggle
    // ======================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_out <= 1'b1;  // Reset → LED kapalı (aktif-low)
        end 
        else if (out_valid && debounced_button) begin
            // sadece basıldığında toggle (bırakmada değil)
            led_out <= ~led_out;
        end
    end

endmodule
![[ButtonLedToggle.v]]

---

## ⚠️ Neden Debounce?

- **Debounce olmadan:**  
    Hızlı bas/çek sırasında LED **titreyerek açılıp kapanır**.  
    FPGA sayıcıları veya FSM’leri yanlış tetikler (tek basış → 2-3 toggle).
    
- **Debounce ile:**  
    Her butona basışta **yalnızca 1 pulse** üretilir.  
    LED **kararlı şekilde toggle** olur, sinyal bozulmaz.
    

---

## 📌 Constraints Dosyası (`.ccf`)

 **Clock input (10 MHz)**
Net "clk"         Loc = "IO_SB_A8";    

 **Push-button input**
Net "push_button" Loc = "IO_EB_B0";    

 **LED output (aktif-low)**
Net "led_out"     Loc = "IO_EB_B1";    


---

📌 Bu proje, önceki **Direct_Button_Led** örneğinin geliştirilmiş versiyonudur.  
Burada **debouncer kullanıldığı için sinyal temizdir** → LED hiçbir zaman kaymaz veya atlama yapmaz.