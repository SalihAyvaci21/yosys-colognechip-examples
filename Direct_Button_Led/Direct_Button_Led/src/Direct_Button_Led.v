`timescale 1ns / 1ps

module Direct_Button_Led(
    input  wire clk,          // sistem clock (kullanılmıyor)
    input  wire push_button,  // buton girişi
    output wire led           // LED çıkışı
);

    // Buton doğrudan LED’e bağlandı
    assign led = push_button;

endmodule
