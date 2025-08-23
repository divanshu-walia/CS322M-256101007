module master_fsm(
    input wire clk,
    input wire rst,
    input wire ack,
    output reg req,
    output reg [7:0] data,
    output reg done
);

    
    localparam IDLE       = 2'b00;
    localparam ASSERT_REQ = 2'b01;
    localparam WAIT_ACK   = 2'b10;
    localparam DROP_REQ   = 2'b11;
    
    
    reg [1:0] state, next_state;
    reg [1:0] byte_count, next_byte_count;
    
    
    reg [7:0] data_array [0:3];
    
    initial begin
        data_array[0] = 8'hA0;
        data_array[1] = 8'hA1;
        data_array[2] = 8'hA2;
        data_array[3] = 8'hA3;
    end
    
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            byte_count <= 2'b00;
        end else begin
            state <= next_state;
            byte_count <= next_byte_count;
        end
    end
    
    
    always @(*) begin
        next_state = state;
        next_byte_count = byte_count;
        
        case (state)
            IDLE: begin
                if (byte_count < 4) begin
                    next_state = ASSERT_REQ;
                end
            end
            
            ASSERT_REQ: begin
                next_state = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (ack) begin
                    next_state = DROP_REQ;
                end
            end
            
            DROP_REQ: begin
                if (!ack) begin
                    next_byte_count = byte_count + 1;
                    if (byte_count == 3) begin
                        next_state = IDLE; 
                    end else begin
                        next_state = IDLE; 
                    end
                end
            end
        endcase
    end
    
    
    always @(*) begin
        req = (state == ASSERT_REQ) || (state == WAIT_ACK);
        data = data_array[byte_count];
        done = (state == DROP_REQ) && (!ack) && (byte_count == 3);
    end

endmodule