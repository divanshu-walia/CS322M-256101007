`timescale 1ns/1ps

module tb_traffic_light;
    reg clk, rst;
    wire ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;
    
   
    reg tick;
    integer cycle_count = 0;
    
    // DUT
    traffic_light dut(
        .clk(clk), .rst(rst), .tick(tick),
        .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
        .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
    );
    
    
    always #5 clk = ~clk;
    
    
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        tick <= (cycle_count % 10 == 9);
    end


    initial begin
        $dumpfile("traffic_light.vcd");
        $dumpvars(0, tb_traffic_light);
    end


    initial begin
        
        clk = 0;
        rst = 1;
        #50 rst = 0;
        
        
        #2000;
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t rst=%b tick=%b | NS: G%b Y%b R%b | EW: G%b Y%b R%b", 
                 $time, rst, tick, ns_g, ns_y, ns_r, ew_g, ew_y, ew_r);
    end
    
endmodule