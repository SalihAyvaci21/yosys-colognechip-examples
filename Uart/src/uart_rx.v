// uart_rx.v
module uart_rx
#(
    parameter CLOCK_FREQ = 50000000,
    parameter BAUD = 115200
)
(
    input  wire clk,
    input  wire rst,
    input  wire rx,         // serial in (idle = 1)
    output reg  [7:0] rx_data,
    output reg  rx_valid
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
