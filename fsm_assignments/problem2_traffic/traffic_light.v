
module tick_prescaler #(
    parameter CLK_FREQ_HZ = 50_000_000,
    parameter TICK_HZ = 1
)(
    input clk, rst,
    output reg tick
);
    localparam TERMINAL = CLK_FREQ_HZ / TICK_HZ - 1;
    reg [$clog2(TERMINAL):0] counter;
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            tick <= 0;
        end else if (counter == TERMINAL) begin
            counter <= 0;
            tick <= 1;
        end else begin
            counter <= counter + 1;
            tick <= 0;
        end
    end
endmodule


module traffic_light(
    input clk, rst, tick,
    output reg ns_g, ns_y, ns_r,
    output reg ew_g, ew_y, ew_r
);
    
    parameter NS_GREEN = 2'b00;
    parameter NS_YELLOW = 2'b01;
    parameter EW_GREEN = 2'b10;
    parameter EW_YELLOW = 2'b11;
    
    reg [1:0] state;
    reg [2:0] count;
    

    always @(posedge clk) begin
        if (rst) begin
            state <= NS_GREEN;
            count <= 0;
        end else if (tick) begin
            case (state)
                NS_GREEN: begin
                    if (count == 4) begin
                        state <= NS_YELLOW;
                        count <= 0;
                    end else
                        count <= count + 1;
                end
                NS_YELLOW: begin
                    if (count == 1) begin
                        state <= EW_GREEN;
                        count <= 0;
                    end else
                        count <= count + 1;
                end
                EW_GREEN: begin
                    if (count == 4) begin
                        state <= EW_YELLOW;
                        count <= 0;
                    end else
                        count <= count + 1;
                end
                EW_YELLOW: begin
                    if (count == 1) begin
                        state <= NS_GREEN;
                        count <= 0;
                    end else
                        count <= count + 1;
                end
            endcase
        end
    end
    
   
    always @(*) begin
        ns_g = 0; ns_y = 0; ns_r = 0;
        ew_g = 0; ew_y = 0; ew_r = 0;
        
        case (state)
            NS_GREEN: begin
                ns_g = 1;
                ew_r = 1;
            end
            NS_YELLOW: begin
                ns_y = 1;
                ew_r = 1;
            end
            EW_GREEN: begin
                ns_r = 1;
                ew_g = 1;
            end
            EW_YELLOW: begin
                ns_r = 1;
                ew_y = 1;
            end
        endcase
    end
endmodule