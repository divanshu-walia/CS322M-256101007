module seq_detect_mealy(input clk,
                        input rst,
                        input din,
                        output y);
    
    reg [1:0] present_state, next_state;
    
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;
    parameter S3 = 2'b11;

    // state register
    always @ (posedge clk, posedge rst)
        begin
            if(rst) present_state <= S0;
            else    present_state <= next_state;
        end
    // next state logic
    always @ (*)
        case (present_state)
            S0: if(din)  
                        next_state = S1;
                else      
                        next_state = S0;

            S1: if(din)  
                        next_state = S2;
                else      
                        next_state = S0;

            S2: if(din)  
                        next_state = S2;
                    else      
                        next_state = S3;

            S3: if(din) 
                        next_state = S1;
                else 
                        next_state = S0;

            default:    next_state = S0;

        endcase

        assign y = (present_state == S3) && din;

endmodule