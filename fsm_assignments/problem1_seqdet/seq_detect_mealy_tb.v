
module seq_detect_mealy_tb;
                    reg clk;
                    reg rst; 
                    reg din;
                    wire y;

        seq_detect_mealy duc(.clk(clk), .rst(rst), .din(din), .y(y));

        initial clk = 0;
        always #5 clk = ~clk;

        initial begin
            $dumpfile("seq_detect_mealy_tb.vcd");
            $dumpvars(0,seq_detect_mealy_tb);
            
            $display(" Starting Testing ");

            $display("Time\tclk\trst\tdin\ty");
            $monitor("%0t\t%b\t%b\t%b\t%b", $time, clk, rst, din, y);

            rst = 1;
            din = 0;
            @(posedge clk);
            @(posedge clk);

            rst = 0;

            // input test
           @(posedge clk) din = 1;
           @(posedge clk) din = 1;
           @(posedge clk) din = 0;
           @(posedge clk) din = 1;

           @(posedge clk) din = 0;

            // overlapping input test stream 
           @(posedge clk) din = 0; 
           @(posedge clk) din = 1;  // 1
           @(posedge clk) din = 1; // 1
           @(posedge clk) din = 0; // 0
           @(posedge clk) din = 1; // 1 -> detect
           @(posedge clk) din = 1; // overlap
           @(posedge clk) din = 0; 
           @(posedge clk) din = 1; // detect again
            
            
            #20 
            $display(" Simulation finished... ");
            $finish;
        end
endmodule