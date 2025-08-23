module tb_vending_mealy;
    reg clk, rst;
    reg [1:0] coin;
    wire dispense, chg5;
    
    vending_mealy dut(.clk(clk), .rst(rst), .coin(coin), 
                      .dispense(dispense), .chg5(chg5));
    
   
    always #5 clk = ~clk;
    
    task put5; 
        begin 
            @(posedge clk); coin=2'b01; 
            @(posedge clk); coin=2'b00; 
        end 
    endtask
    
    task put10; 
        begin 
            @(posedge clk); coin=2'b10; 
            @(posedge clk); coin=2'b00; 
        end 
    endtask
    
    initial begin
        
        $dumpfile("vending.vcd");
        $dumpvars(0, tb_vending_mealy);

        clk=0; rst=1; coin=0;
        #10 rst=0;
        
       
        put10; put10; 
        #10;
        
        
        rst=1; #10 rst=0;
        
        
        put5; put10; put10;
        #10;
        
        $finish;
    end
    
    initial $monitor("t=%0t state=%0d coin=%0d disp=%b chg5=%b", 
                     $time, dut.state, coin, dispense, chg5);
endmodule