`timescale 1ns/1ns

module comp_tb;
        reg A, B;
        wire o1, o2, o3;

        mycomp comp1(.A(A),
                    .B(B),
                    .o1(o1),
                    .o2(o2),
                    .o3(o3)
        );

        initial begin
            $dumpfile("comp_tb.vcd");
            $dumpvars(0, comp_tb);

            $display(" Starting testing on 00, 01, 10, 11 .....");

            A = 0;  B = 0;  #10;

            A = 0;  B = 1;  #10;

            A = 1;  B = 0;  #10;

            A = 1;  B = 1;  #10;

            $display(" Testing Complete...");

            $finish;
        end

endmodule