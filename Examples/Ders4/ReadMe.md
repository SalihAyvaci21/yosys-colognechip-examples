# **Clock Divider (Led_per_sec + Clockworks)**

**Görev Tanımı:**  
FPGA üzerinde sistem saatini **Clockworks** modülü ile bölüp yavaşlatarak, LED’lerde tek tek yanma/sönme paternini gözlemlemek.

Bu devrede **8 LED** sırasıyla yanar ve belirli bir noktada geri başlar. Böylece clock bölmenin çalışma şekli gözle izlenebilir hale gelir.

---

## 🎯 **Amaç**

- Clockworks modülünü kullanarak **saat bölme (gearbox)** mantığını öğrenmek
- Reset mekanizmasının FPGA tasarımlarında nasıl çalıştığını görmek
- LED’lerin binary sayıcıya göre tek tek yanma düzenini gözlemlemek
- FPGA simülasyonunda clock hızının nasıl ayarlanacağını kavramak

---

## 📂 Proje Yapısı

clock_divider/  
│── log/ # Log kayıtları  
│── net/ # Netlist dosyaları  
│── sim/ # Testbench dosyaları (`Led_per_sec_tb.v`)  
│── src/ # Kaynak kod (Led_per_sec.v, clockworks.v, pll_gatemate.v)  
│── Makefile # Build ayarları (yosys, nextpnr, openFPGALoader, icarus)

---

## 💡 Örnek Kod

**Led_per_sec.v (Top-level):**

![[Led_per_sec.v]]

---

**Led_per_sec_tb.v (Testbench):**

![[Led_per_sec_tb.v]]

---

## ⚡ Beklenen Davranış

- LED’ler sırasıyla yanar:  
    `1 → 1,2 → 1,2,3 → 1,2 → 1 → 1,2,3,4` sonra tekrar başa döner.
    
- Binary sayıcı olduğu için LED patterni düzenli bir şekilde akar.
- Clock bölme sayesinde LED geçişleri gözle rahatlıkla takip edilir.

---

## 🔧 Simülasyon ve Çalıştırma

### Bitstream oluşturma

`run.bat synth_vlog`

### Simülasyon

`run.bat sim_vlog`

Örnek çıktı:

`LEDS = 11111111 LEDS = 11111110 LEDS = 11111101 ...`

### FPGA’ya yükleme

`run.bat jtag`

LED’lerde sayıcı paternini görmelisin ✅

---

## 📝 Notlar

- UART RX/TX portları şimdilik kullanılmıyor (ileriki adımlar için placeholder).
- Clockworks modülünün `SLOW` parametresi değiştirilerek LED yanma hızı ayarlanabilir.
- Reset butonu (SW3) FPGA’da aktif düşük olduğundan `~RESET` şeklinde bağlanmıştır.

---

📌 Bu proje, FPGA üzerinde **clock bölme ve reset kontrolünü öğrenmek** için temel bir örnektir.

---

👉 İstersen README’ye, LED dizisinin **gerçek donanımda nasıl gözüktüğüne dair fotoğraf veya GIF** de ekleyebiliriz. Onu da ister misin?