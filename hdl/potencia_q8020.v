
module potencia_q8020(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [7:0] a,
    input wire [7:0] n,
    output reg [99:0] result_q,
    output reg done
);

reg [7:0] a_reg;
reg [3:0] remaining;
reg odd;
reg [79:0] power;
reg [1:0] state;

localparam IDLE = 0, MULT = 1, FINISH = 2;

// Raiz cuadrada entera de 64 bits
function [31:0] isqrt64;
    input [63:0] x;
    reg [65:0] rem;
    reg [65:0] trial;
    reg [31:0] root;
    integer i;
    begin
        rem = 0;
        root = 0;

        for (i = 31; i >= 0; i = i-1) begin
            rem = (rem << 2) |
                  ((x >> (i*2)) & 64'd3);

            trial = ({34'd0, root} << 2) | 66'd1;

            if (rem >= trial) begin
                rem = rem - trial;
                root = (root << 1) | 32'd1;
            end else begin
                root = root << 1;
            end
        end

        isqrt64 = root;
    end
endfunction

wire [31:0] root_q20 =
    isqrt64({16'd0, a_reg, 40'd0});

wire [111:0] odd_product =
    power * root_q20;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        a_reg <= 0;
        remaining <= 0;
        odd <= 0;
        power <= 0;
        result_q <= 0;
        done <= 0;
        state <= IDLE;
    end else begin
        done <= 0;

        case (state)
            IDLE: begin
                if (start) begin
                    a_reg <= a;
                    remaining <= n[3:1];
                    odd <= n[0];
                    power <= 80'd1;
                    state <= MULT;
                end
            end

            MULT: begin
                if (remaining != 0) begin
                    power <= power * a_reg;
                    remaining <= remaining - 1'b1;
                end else begin
                    state <= FINISH;
                end
            end

            FINISH: begin
                if (odd)
                    result_q <= odd_product[99:0];
                else
                    result_q <= {power, 20'd0};

                done <= 1;
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
