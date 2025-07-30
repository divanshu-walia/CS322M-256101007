`timescale 1ns/1ns

module b4_equal_tb;
                reg [3:0] A, B;
                wire eq;

            b4_equal equal1(.A(A),
                            .B(B),
                            .eq(eq)
            );


            initial begin
                $dumpfile("b4_equal_tb.vcd");
                $dumpvars(0,b4_equal_tb);

                $display("Checking Equality Wait.....");

                A = 0000;   B = 0000;   #10;
                A = 0000;   B = 0001;   #10;
                A = 0101;   B = 1010;   #10;
                A = 1001;   B = 1001;   #10;
                A = 1011;   B = 1000;   #10;
                A = 1110;   B = 1110;   #10;
                A = 1111;   B = 1000;   #10;
                A = 1111;   B = 1111;   #10;
                A = 1000;   B = 0000;   #10;

                $display(" Program Complete....");

                $finish;
            end


endmodule