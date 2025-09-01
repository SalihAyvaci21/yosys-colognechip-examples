![[Direct_Button_Led.v]]Tamamdır ⚡ Senin `Direct_Button_Led` örneğin için de önceki formatına uygun bir README hazırladım. Bu README’de özellikle **butona hızlı bas/çek yapıldığında LED’de kayma, titreme ve sinyal bozulması** kısmını vurguladım:

---

# **Direct Button → LED**

**Görev Tanımı:**  
Buton sinyalini doğrudan LED çıkışına bağlayarak, mekanik buton davranışını gözlemlemek.  
Bu devrede **debounce** yapılmadığı için hızlı bas/çek hareketlerinde LED’de **titreme, kayma ve sinyal bozulması** gözlenir.

---

## 🎯 **Amaç**

- Mekanik butonların gerçek davranışını gözlemlemek
- Buton basıldığında LED’in nasıl yanıp söndüğünü görmek
- **Bounce (sıçrama/gürültü)** problemini deneyimlemek
- Debounce devresi olmadan sinyalin neden güvenilmez olduğunu anlamak
    

---

## 📂 Proje Yapısı

direct_button_led/  
│── log/ # Log kayıtları  
│── net/ # Netlist dosyaları  
│── sim/ # Testbench dosyaları  
│── src/ # Kaynak kod (.v) + .ccf constraints  
│── Makefile # Build ayarları  
│── run.bat # Çalıştırma scripti

---

## 💡 Örnek Kod

`timescale 1ns / 1ps

module Direct_Button_Led(
    input  wire clk,          // sistem clock (kullanılmıyor)
    input  wire push_button,  // buton girişi
    output wire led           // LED çıkışı
);

    // Buton doğrudan LED’e bağlandı
    assign led = push_button;

endmodule
![[Direct_Button_Led.v]]

---

## ⚠️ Gözlenen Sorunlar

- **Buton bounce:**  
    Tek bir basış sırasında bile buton içindeki metal kontaklar **birkaç ms boyunca zıplar**.
- **LED’de kayma / titreme:**  
    Butona hızlıca basıp çektiğinde LED birden fazla kez yanıp sönüyormuş gibi görünür.
- **Sinyal bozulması:**  
    Eğer bu buton sayıcı veya toggle kontrolünde kullanılsaydı, tek basış yerine 2–3 kez algılanırdı.
    

---

## 🔧 Çözüm

Bu problemi çözmek için **debouncer** kullanılmalıdır:

- **Donanımsal debounce:** RC filtre, Schmitt Trigger
- **FPGA/MCU tarafında debounce:** shift register tabanlı filtre + tek pulse üretici

---

📌 Bu proje özellikle **debounce devresinin neden gerekli olduğunu** göstermek için temel bir örnektir.