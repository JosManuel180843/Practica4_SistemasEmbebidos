
`timescale 1ns/1ps

module tb_potencia_q8020;

reg clk = 0;
reg reset = 1;
reg start = 0;

reg [7:0] a = 0;
reg [7:0] n = 0;

wire [99:0] result_q;
wire done;

always #10 clk = ~clk;

potencia_q8020 dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .a(a),
    .n(n),
    .result_q(result_q),
    .done(done)
);

task test;
    input [7:0] ta, tn;
    input [99:0] expected;
    begin
        @(negedge clk);
        a = ta;
        n = tn;
        start = 1;

        @(negedge clk);
        start = 0;

        wait(done);

        if (result_q !== expected)
            $display(
                "ERROR A=%0d n=%0d got=%0d expected=%0d",
                ta, tn, result_q, expected
            );
        else
            $display(
                "OK A=%0d n=%0d Q=%0d",
                ta, tn, result_q
            );

        @(negedge clk);
    end
endtask

initial begin
    repeat(3) @(negedge clk);
    reset = 0;

    test(4, 3, 100'd8388608);
    test(9, 3, 100'd28311552);
    test(16, 3, 100'd67108864);
    test(4, 7, 100'd134217728);
    test(2, 0, 100'd1048576);

    $finish;
end

endmodule
