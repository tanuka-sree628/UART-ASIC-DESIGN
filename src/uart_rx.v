`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.08.2026 07:06:14
// Design Name: 
// Module Name: uart_rx
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

module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input clk,
    input reset,
    input rx,
    output reg rx_valid,
    output reg [7:0] rx_data
);

    localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT    = CLK_PER_BIT / 2;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg rx_sync1;
    reg rx_sync2;
    reg rx_syncd;

    wire start_edge;

    reg [12:0] baud_counter;
    reg [2:0]  bit_counter;
    reg [7:0]  rx_reg;
    reg [1:0]  state;

    assign start_edge = rx_syncd && (~rx_sync2);

    always @(posedge clk) begin

        if (reset) begin
            rx_sync1    <= 1'b1;
            rx_sync2    <= 1'b1;
            rx_syncd    <= 1'b1;
            baud_counter <= 0;
            bit_counter  <= 0;
            rx_reg       <= 0;
            rx_data      <= 0;
            rx_valid     <= 1'b0;
            state        <= IDLE;
        end

        else begin

            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            rx_syncd <= rx_sync2;

            rx_valid <= 1'b0;

            case (state)

                IDLE: begin
                    baud_counter <= 0;

                    if (start_edge) begin
                        baud_counter <= 0;
                        bit_counter  <= 0;
                        state        <= START;
                    end
                end

                START: begin
                    if (baud_counter == HALF_BIT - 1) begin
                        baud_counter <= 0;

                        if (rx_sync2 == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                DATA: begin
                    if (baud_counter == CLK_PER_BIT - 1) begin
                        baud_counter <= 0;

                        rx_reg[bit_counter] <= rx_sync2;

                        if (bit_counter == 3'd7) begin
                            bit_counter <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                STOP: begin
                    if (baud_counter == CLK_PER_BIT - 1) begin
                        baud_counter <= 0;

                        if (rx_sync2 == 1'b1) begin
                            rx_data <= rx_reg;
                            rx_valid <= 1'b1;
                        end

                        state <= IDLE;
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                    baud_counter <= 0;
                    bit_counter <= 0;
                end

            endcase
        end
    end

endmodule