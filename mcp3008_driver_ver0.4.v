`timescale 1ns/1ps

module mcp3008_driver (
    input clk,
    input rst_n,
    input start,
    output reg [9:0] x_data_out,
    output reg [9:0] y_data_out,
    output reg data_valid,
    // SPI Interface
    output reg spi_sck,
    output reg spi_cs,
    output reg spi_mosi,
    input      spi_miso
);

    // FSM 상태 정의
    localparam S_IDLE      = 3'd0;
    localparam S_COMM_X    = 3'd1;
	localparam S_DELAY_XY  = 3'd2;
    localparam S_COMM_Y    = 3'd3;
    localparam S_DONE      = 3'd4;

    localparam COMM_BITS   = 16;
	localparam DELAY_CYCLES = 20;
	
    reg [4:0] bit_count;
	reg [4:0] delay_count;
    reg [3:0] state = S_IDLE; 
    reg [9:0] x_buffer, y_buffer;
    
    localparam CMD_CH0 = 5'b11000;
    localparam CMD_CH1 = 5'b11001;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= S_IDLE;
            spi_cs <= 1'b1;
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
            data_valid <= 1'b0;
            bit_count <= 0;
			delay_count <= 0;
            x_data_out <= 0;
            y_data_out <= 0;
            x_buffer <= 0; 
            y_buffer <= 0; 
        end else begin
            data_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        spi_cs <= 1'b0;
                        bit_count <= 0;
                        state <= S_COMM_X;
                    end
                end
                S_COMM_X: begin
                    spi_sck <= ~spi_sck;
                    if (spi_sck == 1'b0) begin
                        if (bit_count < 5) spi_mosi <= CMD_CH0[4 - bit_count];
                        else spi_mosi <= 1'b0;
                    end else begin
                        if (bit_count >= 6) x_buffer <= {x_buffer[8:0], spi_miso};
                        bit_count <= bit_count + 1;
                    end
                    if (bit_count == COMM_BITS) begin
                        delay_count <= 0;
                        state <= S_DELAY_XY;
                    end
                end
				S_DELAY_XY: begin
					spi_sck <= 1'b0;
					spi_mosi <= 1'b0;
					
					if(delay_count == DELAY_CYCLES - 1)begin
						state <= S_COMM_Y;
						bit_count <= 0;
					end else begin
						delay_count <= delay_count + 1;
					end
				end
				
                S_COMM_Y: begin
                    spi_sck <= ~spi_sck;
                    if (spi_sck == 1'b0) begin
                        if (bit_count < 5) spi_mosi <= CMD_CH1[4 - bit_count];
                        else spi_mosi <= 1'b0;
                    end else begin
                        if (bit_count >= 6) y_buffer <= {y_buffer[8:0], spi_miso};
                        bit_count <= bit_count + 1;
                    end
                    if (bit_count == COMM_BITS) begin
                        state <= S_DONE;
                    end
                end
                S_DONE: begin
                    spi_cs <= 1'b1;
                    spi_sck <= 1'b0;
                    x_data_out <= x_buffer;
                    y_data_out <= y_buffer;
                    data_valid <= 1'b1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule