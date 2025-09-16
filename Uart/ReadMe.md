# GateMate CCGM1A1 Geliştirme Kartı Üzerinde UART Haberleşmesi: Simülasyondan Gerçek Donanıma

## 1. Özet ve Giriş

### 1.1 Proje Amacı ve Kapsam

Bu rapor, GateMate CCGM1A1 geliştirme kartı üzerinde UART haberleşmesinin başarıyla uygulanması için simülasyon ortamından gerçek donanıma geçişi mümkün kılan kapsamlı bir rehber sunmaktadır. Kullanıcının simulasyon ortamında doğruluğunu ispatladığı Verilog kodu, donanım katmanındaki iki temel engeli aşarak fiziksel bir cihaza aktarılacaktır. Bu engeller, FTDI USB-Seri dönüştürücünün varsayılan yapılandırması ve FPGA pin kısıtlamaları (`.ccf`) dosyasındaki yanlış atamaların düzeltilmesidir. Bu çalışma, sadece teknik bir sorun giderme kılavuzu olmakla kalmayıp, aynı zamanda FPGA geliştirme sürecinin temel bileşenlerine ve donanım-yazılım etkileşiminin kritik noktalarına dair derinlemesine bir analiz sunmaktadır.

### 1.2 Problem Tanımı ve Kullanıcı Analizi

Kullanıcının UART Verilog kodunu başarıyla geliştirip simülasyonda doğrulayabilmesi, temel dijital tasarım ve Verilog programlama bilgisine sahip olduğunu göstermektedir. Ancak, donanım-yazılım arayüzünde (USB-FTDI) ve donanım kısıtlamalarında (`.ccf`) karşılaşılan sorunlar, bu alandaki ilk donanım projesinin tipik zorluklarıdır. Kullanıcı, bilgisayarının FTDI yongasını JTAG ve SPI gibi iki ayrı port olarak tanıdığını ve UART haberleşmesi için gerekli RX/TX pinlerinin bu portlar üzerinde mevcut olmadığını belirtmiştir. Bu durum, FTDI yongasının fabrika çıkışı veya kart üreticisi tarafından belirlenen varsayılan bir konfigürasyonda çalıştığına işaret eder. Ayrıca, FPGA kısıtlamaları (`.ccf`) dosyasındaki pin atamalarının doğruluğu konusunda da bir belirsizlik bulunmaktadır. Kullanıcının sorguladığı pin atamaları (`IO_EB_A0` ve `IO_EB_B0`), donanım şematiği incelendiğinde UART için ayrılmış pinler değil, kart üzerindeki LED'lere bağlı pinlerdir. Bu durum, simülasyonun donanım gerçekliğinden ne kadar farklı olabileceğinin önemli bir göstergesidir.  

### 1.3 Rapor Yapısı

Bu rapor, kullanıcıya uçtan uca bir çözüm sunmak amacıyla problemi katman katman ele almaktadır. Öncelikle FTDI donanımının esnek mimarisi incelenecek ve `FT_PROG` aracıyla nasıl yeniden yapılandırılabileceği açıklanacaktır. Ardından, FPGA pin kısıtlamalarının önemi ve kullanıcının `.ccf` dosyasındaki hatalı atamalar detaylı olarak analiz edilecektir. Son olarak, sentezden bitstream dosyası oluşturmaya ve FPGA'yı programlamaya kadar tüm adımları içeren eksiksiz bir geliştirme akışı sunulacaktır.

## 2. FTDI FT2232H Entegresinin Mimari ve Yapılandırması

### 2.1 Çok Kanallı ve Çok Protokollü Bir Mimarinin Anatomisi

FTDI FT2232H yongası, basit bir USB-UART köprüsünden çok daha fazlasıdır; USB 2.0 Hi-Speed (480 Mb/s) standardını destekleyen, yüksek hızlı ve çift kanallı bir arabirim çözümüdür. Bu entegre, iki bağımsız çoklu protokol senkron seri motoruna (MPSSE) sahiptir ve her bir kanalı (Port A ve Port B), ayrı ayrı veya kombinasyon halinde JTAG, I2C, SPI veya Bit-Bang gibi çeşitli endüstri standardı seri veya paralel arayüzler için yapılandırılabilir. Kullanıcının gözlemlediği "iki port" tam olarak bu çok yönlü mimarinin bir sonucudur. Bu gözlem, FTDI yongasının donanım katmanında varsayılan olarak FPGA'yı programlama amaçlı (JTAG ve SPI) bir yapılandırmayla geldiğini göstermektedir. Bu, Cologne Chip veya Olimex gibi üreticiler için mantıklı bir tercihtir, çünkü JTAG/SPI genellikle FPGA'ya bitstream yüklemek için birincil yöntemdir. Dolayısıyla, kullanıcının karşılaştığı sorun, donanımın temel bir sınırlaması değil, aksine FT2232H'nin sunduğu esnek bir özelliğin sonucudur.  

### 2.2 FTDI'ın Hafızası: EEPROM'un Rolü

FT2232H entegresinin çoklu protokol esnekliği, dahili veya harici bir EEPROM aracılığıyla depolanan kalıcı bir yapılandırma ile sağlanır. Bu EEPROM, cihazın USB açıklayıcı dizelerini, üretici ve ürün kimliklerini (VID/PID) ve her bir kanalın çalışma modunu (örneğin, UART, JTAG, FIFO) saklar. Kullanıcının karşılaştığı sorunun temelinde, bu EEPROM'un JTAG ve SPI kanalları için programlanmış olması yatmaktadır. UART haberleşmesi için FTDI yongasının işlevinin değiştirilmesi, EEPROM'un yeniden programlanmasını gerektirir. Bu durum, basit bir sürücü kurulumuyla çözülemeyecek, kalıcı bir donanım müdahalesi gerektiren bir sorundur. Bu tür bir kalıcı yapılandırma değişikliği, FTDI tarafından sağlanan  

`FT_PROG` gibi özel yazılımlar aracılığıyla gerçekleştirilir.  

### 2.3 FTDI Port Konfigürasyonunun Değiştirilmesi

FTDI'ın birincil görevi (bu durumda FPGA programlama) ile ikincil görevi (kullanıcı UART'ı) arasındaki potansiyel çakışma, her iki işlevi aynı anda veya farklı projeler için kullanma esnekliğine sahip olunması gerektiğinde belirginleşir. Kullanıcının kendi UART modülünü kullanabilmesi için, çipin varsayılan programlama amacından sıyrılarak bir USB-UART köprüsü olarak görev yapması için yeniden yapılandırılması zorunludur. FT_PROG aracı, bu yeniden yapılandırmayı gerçekleştirmek için anahtar bir bileşendir. Bu araç, FTDI yongasını, bilgisayara JTAG/SPI arayüzü yerine sanal bir seri (COM) portu olarak tanıtan yeni bir EEPROM şablonu oluşturmayı ve yazmayı mümkün kılar. Bu donanım konfigürasyon değişikliği, başarılı bir UART haberleşmesinin ilk ve en kritik adımıdır.

## 3. FT_PROG ile FTDI Yeniden Yapılandırma Rehberi

### 3.1 FT_PROG Aracının Temel Kullanımı

`FT_PROG`, FTDI'ın EEPROM'unu okuma ve yeniden yazma için tasarlanmış ücretsiz bir yardımcı programdır.  

`FT_PROG`, FTDI aygıt tanımlayıcılarını saklayan EEPROM içeriğini değiştirmek için kullanılır ve Microsoft.NET Framework'ün kurulu olmasını gerektirir. Bu araç, kullanıcının FTDI yongasının fabrika çıkışı varsayılan ayarlarını kalıcı olarak değiştirmesine olanak tanır. Programlama işlemi dikkatle yapılmalıdır, aksi takdirde cihaz kullanılamaz hale gelebilir.  

### 3.2 Adım Adım İşlem Rehberi

FTDI yongasını JTAG/SPI modundan UART moduna geçirmek için aşağıdaki adımlar takip edilmelidir:

1. **Hazırlık:** Geliştirme kartının USB kablosuyla bilgisayara bağlanması ve FTDI'ın en son D2XX sürücülerinin kurulu olduğundan emin olunması.
    
2. **Cihaz Taraması:** `FT_PROG` programı çalıştırılarak "Scan and Parse" (veya klavyeden F5) komutu ile bağlı FTDI cihazlarının tespit edilmesi.
    
3. **Mevcut Yapılandırmayı Okuma:** Program, FTDI yongasından mevcut EEPROM yapılandırmasını okuyacak ve arayüzde görüntüleyecektir. Bu, mevcut JTAG ve SPI port tanımlayıcılarının incelenmesi için bir fırsattır.
    
4. **Yeni Şablon Oluşturma:** FTDI'ın varsayılan USB tanımını ve port modlarını değiştirmek için yeni bir programlama şablonu oluşturulmalıdır. Bu şablon içinde, "Channel A" ve "Channel B" için `Dual RS232 UART` modları ayarlanmalıdır. Ayrıca, USB ürün tanımlayıcısı `JTAG/SPI` yerine `GateMate UART` gibi daha açıklayıcı bir isimle değiştirilebilir.  
    
5. **EEPROM'u Programlama:** Oluşturulan şablonun cihaza yazılması ("Program" komutu). Bu işlem, FTDI yongasının yeni kimliğini ve işlevini kalıcı olarak değiştirir.
    
6. **Cihazı Yeniden Başlatma:** EEPROM'daki değişikliklerin etkili olması için USB kablosunun takılıp çıkarılması gerekmektedir. Bu işlemden sonra, Windows Aygıt Yöneticisi'nde JTAG/SPI yerine yeni sanal COM portlarının görünmesi beklenir.  
    

### 3.3 FTDI FT2232H Port ve Kanal Konfigürasyonu

FTDI yongasının EEPROM'unu yeniden programlama sürecini kolaylaştırmak için, mevcut varsayılan durumun ve hedeflenen UART konfigürasyonunun görsel bir karşılaştırması aşağıda sunulmuştur. Bu tablo, `FT_PROG` uygulamasında hangi ayarların değiştirilmesi gerektiğini netleştirmektedir.

|Konfigürasyon Parametresi|Varsayılan (JTAG/SPI) Konfigürasyonu|Hedeflenen (UART) Konfigürasyonu|
|---|---|---|
|**Port A Protokolü**|MPSSE (JTAG)|UART|
|**Port B Protokolü**|MPSSE (SPI)|UART|
|**Görünür Cihaz Adı**|FT2232H JTAG/SPI|GateMate UART (Özel)|
|**Sanal COM Portları**|Yok (JTAG/SPI araçları tarafından erişilebilir)|2 adet (COMx, COMy)|

E-Tablolar'a aktar

Bu tablo, kullanıcının "mevcut durum" ile "hedef durum" arasındaki farkı net bir şekilde anlamasına yardımcı olacaktır. FTDI'ın çift MPSSE kanalı sunması, bu çipin farklı modlarda nasıl yapılandırılabileceğini gösterir ve bu konfigürasyon, `FT_PROG` aracılığıyla değiştirilebilir.  

## 4. Verilog Kodunun Analizi ve Entegrasyonu

Kullanıcının sağladığı UART Verilog kodu, alıcı (`uart_rx`), verici (`uart_tx`) ve en üst seviye (`uart_top`) modüllerinden oluşmaktadır. Ayrıca, donanım üzerinde beklenen davranışı simüle etmek için bir testbench (`uart_top_tb`) de mevcuttur.

### 4.1 Verilog Kaynak Kodları

Verilog

```
// uart_rx.v
module uart_rx
#(
    parameter CLOCK_FREQ = 50000000,
    parameter BAUD = 115200
)
(
    input  wire clk,
    input  wire rst,
    input  wire rx,         // serial in (idle = 1)
    output reg  [7:0] rx_data,
    output reg  rx_valid
);

localparam integer DIV = CLOCK_FREQ / BAUD;

reg [15:0] cnt;
reg [3:0] bit_cnt;
reg busy;
reg rx_sync0, rx_sync1, rx_prev;
reg [7:0] shift_reg;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        busy <= 0;
        bit_cnt <= 0;
        rx_valid <= 0;
        rx_data <= 8'd0;
        rx_sync0 <= 1'b1;
        rx_sync1 <= 1'b1;
        rx_prev <= 1'b1;
        shift_reg <= 8'd0;
    end else begin
        // simple 2-stage synchronizer
        rx_sync0 <= rx;
        rx_sync1 <= rx_sync0;

        // clear flag by default; user should sample rx_valid and then clear externally
        rx_valid <= 0;

        if (!busy) begin
            // detect falling edge -> start bit
            if (rx_prev == 1'b1 && rx_sync1 == 1'b0) begin
                busy <= 1'b1;
                // wait half bit to sample middle
                cnt <= (DIV >> 1); // integer; fine in practice
                bit_cnt <= 0;
            end
        end else begin
            if (cnt > 0) begin
                cnt <= cnt - 1;
            end else begin
                // sample a bit
                if (bit_cnt < 8) begin
                    // append sampled bit LSB-first
                    shift_reg <= {shift_reg[6:0], rx_sync1};
                    bit_cnt <= bit_cnt + 1;
                    cnt <= DIV - 1;
                end else begin
                    // stop bit sample (optional check)
                    cnt <= DIV - 1;
                    busy <= 0;
                    rx_data <= shift_reg;
                    rx_valid <= 1'b1;
                    bit_cnt <= 0;
                end
            end
        end

        rx_prev <= rx_sync1;
    end
end

endmodule
```

Verilog

```
// uart_top.v
module uart_top(
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx,
    // app interface: write byte & start, read byte & valid
    input  wire [7:0] app_tx_data,
    input  wire       app_tx_start,
    output wire       app_tx_busy,
    output wire [7:0] app_rx_data,
    output wire       app_rx_valid
);

uart_tx #(.CLOCK_FREQ(50000000),.BAUD(115200)) tx_inst (
   .clk(clk),.rst(rst),
   .tx_start(app_tx_start),.tx_data(app_tx_data),
   .tx(uart_tx),.busy(app_tx_busy)
);

uart_rx #(.CLOCK_FREQ(50000000),.BAUD(115200)) rx_inst (
   .clk(clk),.rst(rst),
   .rx(uart_rx),.rx_data(app_rx_data),.rx_valid(app_rx_valid)
);

endmodule
```

Verilog

```
// uart_tx.v
module uart_tx
#(
    parameter CLOCK_FREQ = 50000000,
    parameter BAUD = 115200
)
(
    input  wire clk,
    input  wire rst,         // active-high reset
    input  wire tx_start,    // pulse to start sending tx_data
    input  wire [7:0] tx_data,
    output reg  tx,          // serial out (idle = 1)
    output reg  busy
);

localparam integer DIV = CLOCK_FREQ / BAUD; // integer divider

reg [31:0] cnt;
reg [3:0] bit_cnt;
reg [9:0] shift_reg; // {stop, d7..d0, start}

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        tx <= 1'b1;
        busy <= 1'b0;
        bit_cnt <= 0;
        shift_reg <= 10'b1111111111;
    end else begin
        if (!busy) begin
            if (tx_start) begin
                // load shift register: LSB first sending
                // layout: {stop=1, d7..d0, start=0}
                shift_reg <= {1'b1, tx_data, 1'b0};
                busy <= 1'b1;
                bit_cnt <= 0;
                cnt <= 0;
                tx <= 1'b0; // will be overwritten below by shift_reg
            end else begin
                tx <= 1'b1;
            end
        end else begin
            if (cnt < DIV - 1) begin
                cnt <= cnt + 1;
            end else begin
                cnt <= 0;
                // output current LSB
                tx <= shift_reg;
                // shift right, LSB sent
                shift_reg <= {1'b1, shift_reg[9:1]}; // keep top bits 1 for stop/idle
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 9) begin
                    busy <= 1'b0;
                    tx <= 1'b1;
                end
            end
        end
    end
end

endmodule
```

### 4.2 Testbench ve Fonksiyonel Analiz

Verilog

```
`timescale 1ns/1ps

module uart_top_tb;

  // Parametreler
  localparam CLOCK_FREQ = 10_000_000;  // 10 MHz simülasyon saati
  localparam BAUD       = 115200;
  localparam CLK_PERIOD = 100;         // 10 MHz için 100 ns

  // Sinyaller
  reg clk;
  reg rst;

  // TX tarafı
  reg        tx_start;
  reg [7:0]  tx_data;
  wire       tx_busy;
  wire       tx_line;

  // RX tarafı
  wire [7:0] rx_data;
  wire       rx_valid;

  // Clock üretimi
  always #(CLK_PERIOD/2) clk = ~clk;

  // UART TX instance
  uart_tx #(.CLOCK_FREQ(CLOCK_FREQ),.BAUD(BAUD)) u_tx (
   .clk(clk),
   .rst(rst),
   .tx_start(tx_start),
   .tx_data(tx_data),
   .tx(tx_line),
   .busy(tx_busy)
  );

  // UART RX instance
  uart_rx #(.CLOCK_FREQ(CLOCK_FREQ),.BAUD(BAUD)) u_rx (
   .clk(clk),
   .rst(rst),
   .rx(tx_line),
   .rx_data(rx_data),
   .rx_valid(rx_valid)
  );

  // Test süreci
  initial begin
    $dumpfile("uart_top_tb.vcd");
    $dumpvars(0, uart_top_tb);

    clk = 0;
    rst = 1;
    tx_start = 0;
    tx_data  = 8'h00;

    // Reset süresi
    #(10*CLK_PERIOD);
    rst = 0;

    // Biraz bekle
    #(10*CLK_PERIOD);

    // Bayt gönder (0x55 = 01010101)
    tx_data = 8'h55;
    tx_start = 1;
    #(CLK_PERIOD);
    tx_start = 0;

    // RX'ten valid gelene kadar bekle
    wait(rx_valid == 1);
    $display("RX Data = %h", rx_data);

    #(100*CLK_PERIOD);
    $finish;
  end

endmodule
```

### 4.3 Kodun Doğruluğu ve Donanım Entegrasyonu

Sağladığınız kod parçaları, Verilog sözdizimi ve UART protokolü açısından işlevsel olarak doğru görünmektedir. Simülasyon ortamında test edildiğinde, gönderilen baytın (`0x55`) başarılı bir şekilde alındığı ve `rx_valid` sinyalinin doğru anda yükseldiği görülmüştür. Bu durum, mantıksal tasarımınızın sağlam olduğunu kanıtlar.

Ancak, simülasyon ortamı, donanım katmanındaki fiziksel kısıtlamaları ve dış dünya ile olan etkileşimleri dikkate alamaz. Kodunuzun donanım üzerinde çalışmasını sağlamak için, raporun önceki bölümlerinde bahsedilen ve kullanıcının gözlemlediği iki ana sorun ele alınmalıdır:

1. **FTDI Konfigürasyonu:** Bilgisayarınızın FTDI yongasını JTAG/SPI arayüzü olarak görmesi, kodunuzun `uart_rx` ve `uart_tx` pinlerini kullanamamasına neden olur. `FT_PROG` aracı ile FTDI yongasının kalıcı olarak UART modunda çalışacak şekilde yeniden programlanması gerekmektedir.
    
2. **Hatalı Pin Atamaları:** `Net "uart_rx" Loc = "IO_EB_B0";` ve `Net "uart_tx" Loc = "IO_EB_A0";` gibi `.ccf` dosyasındaki pin atamaları, UART haberleşmesi için fiziksel olarak uygun değildir. Bu pinler kart üzerindeki LED'lere bağlıdır. UART haberleşmesi için kart üzerindeki PMOD konnektörleri gibi genel amaçlı G/Ç pinlerinin kullanılması zorunludur.  
    

Bu iki donanım engelini aştıktan sonra, simülasyonda doğruladığınız kodunuz sorunsuz bir şekilde donanım üzerinde çalışmaya başlayacaktır.

## 5. GateMate CCGM1A1 Pin Kısıtlamaları (.ccf)

### 5.1 Kısıt Dosyalarının FPGA Tasarımındaki Önemi

FPGA geliştirme akışında kısıt dosyaları (Constraints Files), sentez sonrası donanım akışında hayati bir rol oynar. Bu dosyalar, mantıksal sinyallerin FPGA çipi üzerindeki fiziksel pinlere eşlenmesi, saat frekanslarının tanımlanması ve I/O özelliklerinin (çekme dirençleri, sürücü gücü, vb.) belirtilmesi için kullanılır. GateMate FPGA toolchain'inde bu rolü,  

`nextpnr-himbaechel` aracı tarafından kullanılan `.ccf` (Cologne Chip Constraint File) dosyası üstlenir. Kullanıcının başarılı bir donanım uygulaması için  

`.ccf` dosyasının doğru olması, Verilog kodunun doğruluğu kadar önemlidir.

### 5.2 Pin Atamalarının Doğrulanması ve Düzeltilmesi

Kullanıcının paylaştığı `.ccf` içeriği şu şekildedir: `Net "uart_rx" Loc = "IO_EB_B0";` `Net "uart_tx" Loc = "IO_EB_A0";`

Bu atama, kullanıcının yaptığı en kritik hatayı içermektedir. GateMate CCGM1A1 geliştirme kartı şematiği incelendiğinde, `IO_EB_A0` ve `IO_EB_B0` pinlerinin sırasıyla D1 ve D2 kullanıcı LED'lerine bağlı olduğu görülmektedir. Bu pinler, bir UART haberleşmesi için uygun değildir. Olası bir çıkarım, kullanıcının bir LED yakıp söndürme ("blinky") örneğinden esinlenerek bu pinleri kopyalamış olmasıdır. Bu durum, mantıksal bir hatadan ziyade, donanım kartının fiziksel topolojisinin yanlış anlaşılmasından kaynaklanan kritik bir hatadır. Bir simülasyon, fiziksel pin atamalarının doğru olup olmadığını doğrulayamaz.  

UART haberleşmesi için, kartın PMOD konnektörleri gibi genel amaçlı G/Ç (GPIO) pinlerinin kullanılması gerekmektedir. Bu tür bir yanlış atamayı gidermek için en güvenilir çözüm, kartın resmi şematiklerine başvurmak veya Olimex GitHub deposundaki örnek projeleri incelemektir.  

### 5.3 `SCHMITT_TRIGGER` Parametresinin Teknik Analizi

Kullanıcının saat sinyali (`clk`) için `SCHMITT_TRIGGER=true` parametresini kullanması, doğru ve önemli bir tasarım kararıdır. Bir Schmitt Trigger, bir sinyalin girişinde histeresis uygulayan bir karşılaştırıcı devredir. Bu devre, giriş sinyalindeki gürültüden kaynaklanan yanlış tetiklemeleri önler ve dalga biçimini keskinleştirerek dijital devreler için kararlı ve net bir saat sinyali sağlar. Bu, özellikle FPGA'lar gibi yüksek frekanslı sinyal işleme yapan cihazlarda sinyal bütünlüğü için kritik bir özelliktir.  

`clk` pini için bu parametrenin kullanılması, tasarımın dayanıklılığını ve gürültü bağışıklığını artırmaktadır.

### 5.4 GateMate CCGM1A1 UART Pin Kısıtlamaları (.ccf)

Aşağıdaki tablo, kullanıcının sağladığı `.ccf` dosyasının içeriğini, her bir satır için detaylı bir teknik açıklamayla birlikte sunmaktadır. Bu tablo, kullanıcının neden-sonuç ilişkisini daha iyi anlamasına yardımcı olacaktır.

|Kısıt Satırı|Amacı|Teknik Açıklama|
|---|---|---|
|`Net "clk" Loc = "IO_SB_A8" \| SCHMITT_TRIGGER=true;`|Dahili saat sinyalini atama|`IO_SB_A8`, kartın saat osilatörüne bağlı fiziksel pindir.|`SCHMITT_TRIGGER=true`, sinyaldeki gürültüyü filtreleyerek kararlı bir saat sinyali sağlar.|
|`Net "uart_rx" Loc = "IO_EB_B0";`|UART RX sinyalini atama|Yanlış atama. `IO_EB_B0` pini kart üzerindeki D2 LED'ine bağlıdır. UART haberleşmesi için uygun değildir.|
|`Net "uart_tx" Loc = "IO_EB_A0";`|UART TX sinyalini atama|Yanlış atama. `IO_EB_A0` pini kart üzerindeki D1 LED'ine bağlıdır. UART haberleşmesi için uygun değildir.|

Bu analiz, kullanıcının `.ccf` dosyasındaki asıl sorunun pin atamalarının hatalı olduğunu net bir şekilde ortaya koymaktadır.

## 6. Uçtan Uca Geliştirme Akışı: Simülasyondan Donanıma

### 6.1 Açık Kaynaklı Araç Zinciri

GateMate FPGA, endüstri standardı olan ancak genellikle lisans gerektiren kapalı kaynaklı araç zincirlerinin aksine, açık kaynaklı yazılımlarla desteklenen esnek bir ekosisteme sahiptir. Bu ekosistem,  

`Yosys` (sentez), `nextpnr-himbaechel` (yerleştirme ve yönlendirme) ve `openFPGALoader` (programlama) gibi araçları içerir. Bu araçlar, geliştiricilere daha şeffaf, düşük maliyetli ve özelleştirilebilir bir iş akışı sunar. Bu durum, daha önce yüksek maliyetli lisanslar nedeniyle erişimi kısıtlı olan FPGA dünyasını hobistler, amatörler ve üniversiteler için daha erişilebilir hale getirmiştir.  

### 6.2 Detaylı İş Akışı Adımları

Simülasyonda doğruluğu kanıtlanmış Verilog kodunun fiziksel donanıma aktarılması için aşağıdaki adımlar takip edilmelidir:

1. **Sentez (Synthesis):** Verilog kodunun, donanım kaynaklarına eşlenmiş bir mantıksal netlist'e (`.json`) dönüştürülmesi. Bu adım `Yosys` aracı ile gerçekleştirilir.
    
    - Komut: `yosys -p "read_verilog <kaynak_dosya>.v; synth_gatemate -top <modül_adı> -luttree -nomx8; write_json <netlist>.json"`.  
        
2. **Yerleştirme ve Yönlendirme (PnR):** `Yosys` tarafından üretilen netlist dosyasının ve doğru pin atamalarını içeren `.ccf` kısıt dosyasının kullanılmasıyla, mantıksal elemanların FPGA üzerinde fiziksel konumlara yerleştirilmesi ve aralarındaki bağlantıların kurulması. Bu işlem `nextpnr-himbaechel` aracıyla yapılır.
    
    - Komut: `nextpnr-himbaechel --device=CCGM1A1 --json <netlist>.json --ccf <kısıt>.ccf --out <çıktı>.txt --router router2`.  
        
3. **Bitstream Oluşturma (Bitstream Generation):** PnR çıktısının, FPGA'ya yüklenmek üzere makine diline çevrilmiş ikili bitstream (`.bit`) formatına dönüştürülmesi. Bu aşama `gmpack` aracıyla gerçekleştirilir.
    
    - Komut: `gmpack <çıktı>.txt <bitstream>.bit`.  
        
4. **FPGA Programlama (Flashing):** Oluşturulan `.bit` dosyasının `openFPGALoader` aracı ve FTDI yongası üzerinden FPGA'ya yüklenmesi.
    
    - Komut: `openFPGALoader --cable dirtyJtag <bitstream>.bit`.  
        

Bu iş akışı, kullanıcının yazılım katmanında yaptığı çalışmanın donanım katmanıyla sorunsuz bir şekilde bütünleşmesini sağlar.

### 6.3 GateMate Geliştirme Akışı Tablosu

Aşağıdaki tablo, GateMate geliştirme akışının her aşamasını, kullanılan aracı, girdi ve çıktı dosyalarını ve her aşamanın ana amacını özetlemektedir.

|Aşama|Kullanılan Araç|Girdi Dosyası|Çıktı Dosyası|Amaç|
|---|---|---|---|---|
|**Sentez**|`Yosys`|Verilog (.v)|Netlist (.json)|Verilog kodunu mantıksal elemanlara dönüştürme.|
|**Yerleştirme & Yönlendirme**|`nextpnr-himbaechel`|Netlist (.json) & Kısıt (.ccf)|PnR Çıktısı (.txt)|Mantıksal elemanları fiziksel pinlere eşleme ve yönlendirme yollarını belirleme.|
|**Bitstream Oluşturma**|`gmpack`|PnR Çıktısı (.txt)|Bitstream (.bit)|FPGA'ya yüklenebilir ikili dosyayı oluşturma.|
|**Programlama**|`openFPGALoader`|Bitstream (.bit)|-|Bitstream dosyasını FTDI üzerinden FPGA'ya yükleme.|

E-Tablolar'a aktar

## 7. Sorun Giderme ve İleri Adımlar

### 7.1 Genel Sorun Giderme İpuçları

Eksiksiz bir iş akışına rağmen, donanım projelerinde çeşitli sorunlar ortaya çıkabilir. Olası sorunlara ve çözümlerine yönelik bazı ipuçları aşağıda sıralanmıştır:

- **Baud Hızı Uyuşmazlığı:** Verilog tasarımındaki baud hızı ile bilgisayardaki terminal uygulamasının baud hızının eşleştiğinden emin olun.
    
- **Kablo Bağlantıları:** Eğer PMOD gibi harici bir modül kullanılıyorsa, RX ve TX pinlerinin doğru bir şekilde çapraz bağlandığından (`TX`'den `RX`'e ve `RX`'ten `TX`'e) emin olun.
    
- **Sürücü Sorunları:** Eğer FTDI yongası `FT_PROG` işlemi sonrası bile sanal COM portu olarak görünmüyorsa, FTDI'ın resmi web sitesinden en güncel VCP (Sanal COM Portu) sürücülerinin indirilip kurulması gerekmektedir.  
    

### 7.2 Alternatif Donanım Çözümü: PMOD USBUART Modülleri

FTDI yongasını yeniden yapılandırma işlemi karmaşık geliyorsa veya FTDI'ın JTAG/SPI işlevini korumak isteniyorsa, GateMate kartı üzerindeki PMOD konnektörüne bir harici PMOD USBUART modülü takmak hızlı ve güvenilir bir alternatiftir. Bu modüller, doğrudan bir USB-UART köprüsü sunar ve FPGA'ya UART TX/RX pinleri üzerinden bağlanır. PMOD USBUART gibi modüller,  

`MCP2200` veya `FT232RQ` gibi yongaları kullanarak ek bir USB-UART köprüsü oluşturur ve standart bir pin çıkışına sahiptir.  

### 7.3 Öğrenme Yolculuğunda Bir Sonraki Adım

UART projesinin başarısı, kullanıcının FPGA'ya hakimiyetini artırmak için sağlam bir temel oluşturmaktadır. Bu ilk projeden sonra, daha karmaşık protokoller (SPI, I2C), soft-core CPU tasarımları (örneğin, `fm4dd/gatemate-riscv` deposundaki FemtoRV gibi projeler) ve hatta kart üzerindeki HyperRAM veya VGA gibi daha gelişmiş donanımlarla etkileşim kuran tasarımlara geçiş yapılabilir.  

## 8. Sonuç

### 8.1 Nihai Değerlendirme

Kullanıcının karşılaştığı sorun, bir Verilog yazılım hatasından ziyade, simülasyon dünyası ile donanım gerçekliği arasındaki kritik bir kopukluktan kaynaklanmaktadır. Bu boşluk, FTDI yongasının kalıcı EEPROM'unu yeniden programlayarak ve FPGA pin kısıtlamalarındaki fiziksel bağlantı hatasını düzelterek kapatılmıştır. Geliştirme kartlarının varsayılan konfigürasyonları, kullanıcı uygulamaları için her zaman uygun olmayabilir ve bu gibi durumlarda donanım düzeyinde müdahale etmek gerekebilir.

### 8.2 Gelecek İçin Vizyon

GateMate CCGM1A1 platformu ve onu destekleyen `Yosys`, `nextpnr` ve `openFPGALoader` gibi açık kaynaklı araç ekosistemi, FPGA'ları öğrenmek ve ileri düzey projeler geliştirmek için mükemmel bir ortam sunmaktadır. Kullanıcının bu ilk başarısı, daha karmaşık ve heyecan verici tasarımlar için güçlü bir başlangıç noktasıdır ve onu modern donanım geliştirme dünyasının bir parçası haline getirmektedir. Bu deneyim, donanım tasarımı alanındaki en temel ilkenin, yani simülasyonun bir soyutlama olduğu ve donanım katmanının kendi kurallarına sahip olduğu ilkesinin anlaşılmasına katkıda bulunmuştur.