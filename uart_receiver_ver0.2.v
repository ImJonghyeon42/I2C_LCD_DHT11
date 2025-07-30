//'악수' 기능 추가: 데이터 수신이 완료되면 rx_valid 신호를 1로 만들고 계속 유지합니다. 상위 모듈이 데이터를 가져갔다는 확인 신호(rx_read_en)를 받을 때까지 기다렸다가, 확인 신호를 받으면 rx_valid를 다시 0으로 내립니다.
module uart_receiver #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input               clk,
    input               reset,
    input               rxd,
	input				rx_read_en, // handshake signal
    output reg  [7:0]   rx_data,
    output reg          rx_valid,
    output      [2:0]   debug_state
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // FSM States
    localparam S_IDLE      = 3'b000;
    localparam S_START_BIT = 3'b001;
    localparam S_DATA_BITS = 3'b010;
    localparam S_STOP_BIT  = 3'b011;
    localparam S_CLEANUP   = 3'b100;
	localparam S_WAIT_READ = 3'b101;

    reg [2:0] state;
    assign debug_state = state;

    reg [15:0] clk_counter;
    reg [3:0]  bit_index;
    reg [7:0]  rx_buffer;

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            state       <= S_IDLE;
            rx_valid    <= 1'b0;
            clk_counter <= 0;
            bit_index   <= 0;
        end else begin            
            case (state)
                S_IDLE: begin
					rx_valid <= 1'b0;
                    if (rxd == 1'b0) begin // Start bit detected
                        state       <= S_START_BIT;
                        clk_counter <= 0;
                    end
                end

                S_START_BIT: begin
                    if (clk_counter == CLKS_PER_BIT / 2) begin
                        if (rxd == 1'b0) begin // Confirm it's a valid start bit
                            state       <= S_DATA_BITS;
                            clk_counter <= 0;
                            bit_index   <= 0;
                        end else begin
                            state <= S_IDLE; // Glitch, return to idle
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_DATA_BITS: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        rx_buffer[bit_index] <= rxd;
                        if (bit_index == 7) begin
                            state <= S_STOP_BIT;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_STOP_BIT: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        // We don't strictly check the stop bit, but could add error flag here
                        state       <= S_CLEANUP;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                S_CLEANUP: begin
                    rx_data  <= rx_buffer;
                    rx_valid <= 1'b1;
                    state    <= S_WAIT_READ;
                end
				
				S_WAIT_READ: begin
					if(rx_read_en) begin
						state <= S_IDLE;
						rx_valid <= 1'b0;
					end
				end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule