`timescale 1ns/1ps

module uart_top_tb;

  // Parametreler
  localparam CLOCK_FREQ = 10_000_000;  // 10 MHz simülasyon saati
  localparam BAUD       = 115200;
  localparam CLK_PERIOD = 100;         // 10 MHz için 100 ns

  // Sinyaller
  reg clk;
  reg rst;

  // TX tarafı
  reg        tx_start;
  reg [7:0]  tx_data;
  wire       tx_busy;
  wire       tx_line;

  // RX tarafı
  wire [7:0] rx_data;
  wire       rx_valid;

  // Clock üretimi
  always #(CLK_PERIOD/2) clk = ~clk;

  // UART TX instance
  uart_tx #(.CLOCK_FREQ(CLOCK_FREQ), .BAUD(BAUD)) u_tx (
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx_line),
    .busy(tx_busy)
  );

  // UART RX instance
  uart_rx #(.CLOCK_FREQ(CLOCK_FREQ), .BAUD(BAUD)) u_rx (
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
    tx_data  = 8'h00;

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
