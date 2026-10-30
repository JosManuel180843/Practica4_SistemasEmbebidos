
module top_uart_de10lite(
    input wire CLOCK_50,
    input wire RESET_N,
    input wire UART_RX,
    output wire UART_TX
);

wire reset = ~RESET_N;

wire [7:0] rx_data;
wire rx_done;
wire tx_busy;
wire calc_done;
wire [99:0] calc_result;

reg [7:0] a_reg;
reg [7:0] n_reg;
reg [7:0] tx_data;

reg calc_start;
reg tx_start;

reg [99:0] result_reg;
reg [3:0] byte_index;
reg [2:0] state;

localparam WAIT_A = 0,
           WAIT_N = 1,
           CALC = 2,
           WAIT_CALC = 3,
           SEND = 4,
           WAIT_BUSY = 5,
           WAIT_IDLE = 6;

uart_rx #(
    .CLK_FREQ(50000000),
    .BAUD_RATE(9600)
) RX0 (
    .clk(CLOCK_50),
    .reset(reset),
    .rx(UART_RX),
    .data_out(rx_data),
    .data_valid(rx_done)
);

uart_tx #(
    .CLK_FREQ(50000000),
    .BAUD_RATE(9600)
) TX0 (
    .clk(CLOCK_50),
    .reset(reset),
    .tx_start(tx_start),
    .data_in(tx_data),
    .tx(UART_TX),
    .busy(tx_busy)
);

potencia_q8020 POWER0 (
    .clk(CLOCK_50),
    .reset(reset),
    .start(calc_start),
    .a(a_reg),
    .n(n_reg),
    .result_q(calc_result),
    .done(calc_done)
);

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        a_reg <= 0;
        n_reg <= 0;
        tx_data <= 0;
        calc_start <= 0;
        tx_start <= 0;
        result_reg <= 0;
        byte_index <= 0;
        state <= WAIT_A;
    end else begin
        tx_start <= 0;
        calc_start <= 0;

        case (state)
            WAIT_A: begin
                if (rx_done) begin
                    a_reg <= rx_data;
                    state <= WAIT_N;
                end
            end

            WAIT_N: begin
                if (rx_done) begin
                    n_reg <= rx_data;
                    state <= CALC;
                end
            end

            CALC: begin
                calc_start <= 1;
                state <= WAIT_CALC;
            end

            WAIT_CALC: begin
                if (calc_done) begin
                    result_reg <= calc_result;
                    byte_index <= 0;
                    state <= SEND;
                end
            end

            SEND: begin
                if (!tx_busy) begin
                    tx_data <= result_reg[7:0];
                    tx_start <= 1;
                    state <= WAIT_BUSY;
                end
            end

            WAIT_BUSY: begin
                if (tx_busy)
                    state <= WAIT_IDLE;
            end

            WAIT_IDLE: begin
                if (!tx_busy) begin
                    result_reg <= result_reg >> 8;

                    if (byte_index == 12)
                        state <= WAIT_A;
                    else begin
                        byte_index <= byte_index + 1'b1;
                        state <= SEND;
                    end
                end
            end

            default: state <= WAIT_A;
        endcase
    end
end

endmodule
