module slave_fsm(
    input wire clk,
    input wire rst,
    input wire req,
    input wire [7:0] data_in,
    output reg ack,
    output reg [7:0] last_byte
);

    
    localparam WAIT_REQ   = 2'b00;
    localparam ASSERT_ACK = 2'b01;
    localparam HOLD_ACK   = 2'b10;
    localparam DROP_ACK   = 2'b11;
    
    reg [1:0] state, next_state;
    
    
    always @(posedge clk) begin
        if (rst) begin
            state <= WAIT_REQ;
        end else begin
            state <= next_state;
        end
    end
    
   
    always @(*) begin
        case (state)
            WAIT_REQ: begin
                if (req) begin
                    next_state = ASSERT_ACK;
                end else begin
                    next_state = WAIT_REQ;
                end
            end
            
            ASSERT_ACK: begin
                next_state = HOLD_ACK;
            end
            
            HOLD_ACK: begin
                next_state = DROP_ACK;
            end
            
            DROP_ACK: begin
                if (!req) begin
                    next_state = WAIT_REQ;
                end else begin
                    next_state = DROP_ACK;
                end
            end
        endcase
    end
    
   
    always @(posedge clk) begin
        if (rst) begin
            ack <= 1'b0;
            last_byte <= 8'h00;
        end else begin
            
            ack <= (state == ASSERT_ACK) || (state == HOLD_ACK);
            
            
            if (req && state == WAIT_REQ) begin
                last_byte <= data_in;
            end
        end
    end

endmodule
