// uart_top.v
module uart_top(
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx,
    // app interface: write byte & start, read byte & valid
    input  wire [7:0] app_tx_data,
    input  wire       app_tx_start,
    output wire       app_tx_busy,
    output wire [7:0] app_rx_data,
    output wire       app_rx_valid
);

uart_tx #(.CLOCK_FREQ(50000000), .BAUD(115200)) tx_inst (
    .clk(clk), .rst(rst),
    .tx_start(app_tx_start), .tx_data(app_tx_data),
    .tx(uart_tx), .busy(app_tx_busy)
);

uart_rx #(.CLOCK_FREQ(50000000), .BAUD(115200)) rx_inst (
    .clk(clk), .rst(rst),
    .rx(uart_rx), .rx_data(app_rx_data), .rx_valid(app_rx_valid)
);

endmodule
