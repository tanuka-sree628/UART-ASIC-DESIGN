`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.08.2026 17:30:10
// Design Name: 
// Module Name: uart_tx_tb
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

module uart_tb;

    reg clk;
    reg reset;
    reg tx_start;
    reg [7:0] tx_data;

    wire tx;
    wire tx_busy;
    wire rx_valid;
    wire [7:0] rx_data;

    uart_tx #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(10000000)
    ) tx_inst (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(10000000)
    ) rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(tx),
        .rx_valid(rx_valid),
        .rx_data(rx_data)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid)
            $display("Received: %h", rx_data);
    end

    task send_byte;
        input [7:0] data;
        begin
            @(negedge clk);
            tx_data  = data;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            wait(tx_busy == 1'b0);
            #100;
        end
    endtask

    initial begin
        clk      = 0;
        reset    = 1;
        tx_start = 0;
        tx_data  = 8'h00;

        #20;
        reset = 0;

        #100;

        send_byte(8'hA5);
        send_byte(8'h55);
        send_byte(8'h00);
        send_byte(8'hFF);

        #1500;

        $finish;
    end

endmodule
