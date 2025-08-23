module vending_mealy(
    input wire clk,
    input wire rst,        
    input wire [1:0] coin, 
    output reg dispense,   
    output reg chg5        
);

    
    reg [1:0] state; 
    
    
    always @(posedge clk) begin
        if (rst) 
            state <= 2'b00;
        else case (state)
            2'b00: if (coin==2'b01) state <= 2'b01;      
                   else if (coin==2'b10) state <= 2'b10; 
            
            2'b01: if (coin==2'b01) state <= 2'b10;      
                   else if (coin==2'b10) state <= 2'b11; 
            
            2'b10: if (coin==2'b01) state <= 2'b11;      
                   else if (coin==2'b10) state <= 2'b00; 
            
            2'b11: if (coin==2'b01) state <= 2'b00;      
                   else if (coin==2'b10) state <= 2'b00; 
        endcase
    end
    
    
    always @(*) begin
        dispense = 0;
        chg5 = 0;
        
        case (state)
            2'b10: if (coin==2'b10) dispense = 1;        
            2'b11: if (coin==2'b01) dispense = 1;        
                   else if (coin==2'b10) begin
                       dispense = 1;                      
                       chg5 = 1;                          
                   end
        endcase
    end

endmodule
