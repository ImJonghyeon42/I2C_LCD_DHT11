//timer_start 신호는 pump_controller에서 단 한 클럭 동안만 1이 되는 '펄스' 신호입니다. 펌프가 5초 동안 동작하고 나서 이 코드가 실행될 때쯤에는 timer_start 신호는 이미 오래전에 0으로 돌아간 상태입니다.
// 이 조건문은 항상 거짓이 되어, 펌프는 주기적인 동작을 반복하지 못하고 항상 S_IDLE 상태로 돌아가 멈춰버립니다.
//이 문제를 해결하기 위해, pump_timer_logic 모듈에 periodic_mode_active라는 1비트짜리 '메모리(레지스터)'를 추가했습니다.
`timescale 1ns/1ps
module pump_timer_logic #(
    parameter CLOCK_FREQ = 1_000_000 // 100MHz 시스템 클럭
)(
    input  wire         clk,
    input  wire         rst_n,          // Active-low 리셋
    input  wire [1:0]   pump_select,    // 동작시킬 펌프 선택 (01, 10, 11)
    input  wire [31:0]  period_seconds, // 펌프 동작 주기 (초 단위)
    input  wire [31:0]  pulse_on_time,  // 펌프가 켜져 있는 시간 (초 단위)
    input  wire         timer_start,    // 주기 타이머 시작/재시작 신호 (1-pulse)
    input  wire         force_pulse,    // 펌프 강제 동작 신호 (1-pulse)
	input  wire			timer_stop,
    output reg  [1:0]   pump_out
);

    // -- Internal Registers --
    reg [31:0] period_counter;   // 주기 카운터
    reg [31:0] pulse_counter;    // 펄스 카운터
    
    // FSM States
    localparam S_IDLE = 0;       // 대기 상태
    localparam S_WAIT_PERIOD = 1; // 주기 대기 상태
    localparam S_PULSE_ON = 2;    // 펌프 동작 상태

    reg [1:0] state;
    
    // -- Edge Detection for Inputs --
	reg period_mode_active;
	
    reg timer_start_prev;
    wire timer_start_rise = timer_start && ~timer_start_prev;
    
    reg force_pulse_prev;
    wire force_pulse_rise = force_pulse && ~force_pulse_prev;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            timer_start_prev <= 1'b0;
            force_pulse_prev <= 1'b0;
        end else begin
            timer_start_prev <= timer_start;
            force_pulse_prev <= force_pulse;
        end
    end

    // -- Main Timer and Pump Logic --
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= S_IDLE;
            period_counter <= 0;
            pulse_counter <= 0;
            pump_out <= 2'b00;
        end else if(timer_stop) begin
			state <= S_IDLE;
			pump_out <= 2'b00;
			period_mode_active <= 1'b0;
			period_counter <= 0;
			pulse_counter <= 0;
		end
		else begin
			if(timer_start_rise) begin
				state <= S_WAIT_PERIOD;
				period_counter <= 0;
				pulse_counter <= 0;
				pump_out <= 2'b00;
				period_mode_active <= 1'b1;
			end 
			else begin
				case (state)
					S_IDLE: begin
						pump_out <= 2'b00;
						period_mode_active <= 1'b0;
						// 주기 타이머가 시작되면 주기를 기다리는 상태로 전환
						if (timer_start_rise) begin
							state <= S_PULSE_ON;
							period_counter <= 0;
						// 강제 펄스 신호가 들어오면 즉시 펌프를 켜는 상태로 전환
						end else if (force_pulse_rise) begin
							state <= S_PULSE_ON;
							pulse_counter <= 0;
						end
					end
                
					S_WAIT_PERIOD: begin
						// 주기 시간이 다 될 때까지 카운트
						if (period_counter >= (period_seconds * CLOCK_FREQ) - 1) begin
							state <= S_PULSE_ON;
							pulse_counter <= 0;
						end else begin
							period_counter <= period_counter + 1;
						end
                    
						// 대기 중에도 강제 펄스 신호를 받으면 즉시 펌프를 켬
						if (force_pulse_rise) begin
							state <= S_PULSE_ON;
							pulse_counter <= 0;
						end
					end

					S_PULSE_ON: begin
						pump_out <= pump_select; // 선택된 펌프를 켬
						// 펄스 유지 시간이 다 될 때까지 카운트
						if (pulse_counter >= (pulse_on_time * CLOCK_FREQ) - 1) begin
							pump_out <= 2'b00;
							// 주기 타이머가 활성화된 상태였다면 다시 주기를 기다리고, 아니면 대기 상태로 복귀
							if(period_mode_active) begin
								state <= S_WAIT_PERIOD;
								period_counter <= 0;
							end
							else begin
								state <= S_IDLE;
							end													
						end else begin
							pulse_counter <= pulse_counter + 1;
						end
					end
                
					default: state <= S_IDLE;
				endcase
            end
        end
    end

endmodule
