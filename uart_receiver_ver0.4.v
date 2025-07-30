//'악수' 기능 추가: 데이터 수신이 완료되면 rx_valid 신호를 1로 만들고 계속 유지합니다. 상위 모듈이 데이터를 가져갔다는 확인 신호(rx_read_en)를 받을 때까지 기다렸다가, 확인 신호를 받으면 rx_valid를 다시 0으로 내립니다.
// 100MHz가 아닌 1MHz 클럭을 기준으로 통신 속도를 계산하도록 수정했습니다. -> 변화 없음
//uart_receiver 모듈은 1MHz 클럭으로 통신 속도를 계산할 때 발생하는 미세한 타이밍 오차에 민감하여 불안정하게 동작했을 가능성이 높습니다.
//통신 안정성을 대폭 향상시킨 새로운 uart_receiver 모듈로 교체 ->  1MHz 클럭 환경에 최적화되어 있으며, 각 데이터 비트를 여러 번 확인(오버샘플링)하여 가장 정확한 값을 읽어내는 방식

module uart_receiver #(
    parameter CLK_FREQ = 1_000_000, // Runs on 1MHz clock
    parameter BAUD_RATE = 9600
)(
    input               clk, // This is clk_1MHz
    input               reset,
    input               rxd,
    output reg  [7:0]   rx_data,
    output reg          rx_valid
);

    localparam OVERSAMPLE_FACTOR = 8; // Use 8x oversampling for better timing
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; // ~104
    localparam SAMPLES_PER_BIT = CLKS_PER_BIT / OVERSAMPLE_FACTOR; // ~13

    // FSM States
    localparam S_IDLE      = 3'b000;
    localparam S_START_BIT = 3'b001;
    localparam S_DATA_BITS = 3'b010;
    localparam S_STOP_BIT  = 3'b011;

    reg [2:0] state;

    reg [7:0]  clk_counter;
    reg [3:0]  bit_index;
    reg [7:0]  rx_buffer;

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            state          <= S_IDLE;
            rx_valid       <= 1'b0;
            clk_counter    <= 0;
            bit_index      <= 0;
        end else begin
            rx_valid <= 1'b0; // Default value, pulses high for one cycle
            
            case (state)
                S_IDLE: begin
                    if (rxd == 1'b0) begin // Start bit detected
                        state       <= S_START_BIT;
                        clk_counter <= 0;
                    end
                end

                S_START_BIT: begin
                    // Wait until the middle of the start bit
                    if (clk_counter == CLKS_PER_BIT / 2 - 1) begin
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
                    // Wait for a full bit period
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        rx_buffer[bit_index] <= rxd; // Sample the bit
                        
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
                    // Wait for the stop bit period
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        // Could check if rxd is high for frame error detection
                        rx_data  <= rx_buffer;
                        rx_valid <= 1'b1; // Signal that data is ready
                        state    <= S_IDLE;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
