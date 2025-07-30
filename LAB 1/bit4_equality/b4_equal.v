module b4_equal(input [3:0] A, B,
                output eq);

                assign eq = &(~(A - B));
endmodule