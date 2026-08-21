`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.08.2026 15:07:52
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input clk,
    input reset,
    input tx_start,
    input [7:0] tx_data,
    output tx,
    output tx_busy
);

    localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [12:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] tx_reg;
    reg [1:0] state;

    wire baud_tick;

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    assign baud_tick = (state != IDLE) &&
                       (baud_counter == CLK_PER_BIT - 1);

    always @(posedge clk) begin
        if (reset) begin
            baud_counter <= 0;
            bit_counter  <= 0;
            tx_reg       <= 0;
            state        <= IDLE;
        end
        else begin
            if (state == IDLE) begin
                baud_counter <= 0;
            end
            else if (baud_counter == CLK_PER_BIT - 1) begin
                baud_counter <= 0;
            end
            else begin
                baud_counter <= baud_counter + 1;
            end

            case (state)
                IDLE: begin
                    if (tx_start) begin
                        tx_reg      <= tx_data;
                        bit_counter <= 0;
                        state       <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        if (bit_counter == 3'd7) begin
                            bit_counter <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    assign tx = (state == IDLE)  ? 1'b1 :
                (state == START) ? 1'b0 :
                (state == DATA)  ? tx_reg[bit_counter] :
                (state == STOP)  ? 1'b1 :
                                   1'b1;
    
    assign tx_busy = (state != IDLE);

endmodule
