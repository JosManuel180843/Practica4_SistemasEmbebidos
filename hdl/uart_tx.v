
module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] data_in,
    output reg tx,
    output reg busy
);

localparam integer CLKS_PER_BIT =
    CLK_FREQ / BAUD_RATE;

reg [15:0] count;
reg [3:0] index;
reg [9:0] frame;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx <= 1'b1;
        busy <= 0;
        count <= 0;
        index <= 0;
        frame <= 10'h3FF;
    end else if (!busy) begin
        tx <= 1'b1;

        if (tx_start) begin
            frame <= {1'b1, data_in, 1'b0};
            tx <= 0;
            busy <= 1;
            count <= 0;
            index <= 0;
        end
    end else if (count == CLKS_PER_BIT-1) begin
        count <= 0;

        if (index == 9) begin
            busy <= 0;
            tx <= 1;
        end else begin
            index <= index + 1'b1;
            frame <= {1'b1, frame[9:1]};
            tx <= frame[1];
        end
    end else begin
        count <= count + 1'b1;
    end
end

endmodule
