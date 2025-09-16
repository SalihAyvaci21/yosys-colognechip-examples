// uart_tx.v
module uart_tx
#(
    parameter CLOCK_FREQ = 50000000,
    parameter BAUD = 115200
)
(
    input  wire clk,
    input  wire rst,         // active-high reset
    input  wire tx_start,    // pulse to start sending tx_data
    input  wire [7:0] tx_data,
    output reg  tx,          // serial out (idle = 1)
    output reg  busy
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
                tx <= 1'b0; // will be overwritten below by shift_reg[0]
            end else begin
                tx <= 1'b1;
            end
        end else begin
            if (cnt < DIV - 1) begin
                cnt <= cnt + 1;
            end else begin
                cnt <= 0;
                // output current LSB
                tx <= shift_reg[0];
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
