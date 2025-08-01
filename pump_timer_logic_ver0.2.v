`timescale 1ns/1ps

//
// Module: pump_timer_logic
// Description: 설정된 주기에 따라 펌프를 동작시키거나, 외부 신호로 강제 동작시킵니다.
//
module pump_timer_logic #(
    parameter CLOCK_FREQ = 100_000_000 // 100MHz 시스템 클럭
)(
    input  wire         clk,
    input  wire         rst_n,          // Active-low 리셋
    input  wire [1:0]   pump_select,    // 동작시킬 펌프 선택 (01, 10, 11)
    input  wire [31:0]  period_seconds, // 펌프 동작 주기 (초 단위)
    input  wire [31:0]  pulse_on_time,  // 펌프가 켜져 있는 시간 (초 단위)
    input  wire         timer_start,    // 주기 타이머 시작/재시작 신호 (1-pulse)
    input  wire         force_pulse,    // 펌프 강제 동작 신호 (1-pulse)
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
        end else begin
            case (state)
                S_IDLE: begin
                    pump_out <= 2'b00;
                    // 주기 타이머가 시작되면 주기를 기다리는 상태로 전환
                    if (timer_start_rise) begin
                        state <= S_WAIT_PERIOD;
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
                        // 주기 타이머가 활성화된 상태였다면 다시 주기를 기다리고, 아니면 대기 상태로 복귀
                        state <= timer_start ? S_WAIT_PERIOD : S_IDLE;
                        period_counter <= 0;
                        pump_out <= 2'b00;
                    end else begin
                        pulse_counter <= pulse_counter + 1;
                    end
                end
                
                default: state <= S_IDLE;
            endcase

            // 어떤 상태에서든 타이머 시작/재시작 신호를 받으면 처음부터 다시 시작
            if (timer_start_rise) begin
                state <= S_WAIT_PERIOD;
                period_counter <= 0;
                pulse_counter <= 0;
                pump_out <= 2'b00;
            end
        end
    end

endmodule
