
module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);

localparam integer CLKS_PER_BIT =
    CLK_FREQ / BAUD_RATE;

localparam integer HALF_BIT =
    CLKS_PER_BIT / 2;

localparam [1:0]
    IDLE = 0,
    START = 1,
    DATA = 2,
    STOP = 3;

reg [1:0] state;
reg [15:0] count;
reg [2:0] bit_index;
reg [7:0] shift;
reg meta, sync;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        meta <= 1;
        sync <= 1;
    end else begin
        meta <= rx;
        sync <= meta;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        count <= 0;
        bit_index <= 0;
        shift <= 0;
        data_out <= 0;
        data_valid <= 0;
    end else begin
        data_valid <= 0;

        case (state)
            IDLE: begin
                count <= 0;
                bit_index <= 0;
                if (!sync)
                    state <= START;
            end

            START: begin
                if (count == HALF_BIT-1) begin
                    count <= 0;
                    if (!sync)
                        state <= DATA;
                    else
                        state <= IDLE;
                end else
                    count <= count + 1'b1;
            end

            DATA: begin
                if (count == CLKS_PER_BIT-1) begin
                    count <= 0;
                    shift[bit_index] <= sync;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1'b1;
                end else
                    count <= count + 1'b1;
            end

            STOP: begin
                if (count == CLKS_PER_BIT-1) begin
                    count <= 0;
                    state <= IDLE;

                    if (sync) begin
                        data_out <= shift;
                        data_valid <= 1;
                    end
                end else
                    count <= count + 1'b1;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
